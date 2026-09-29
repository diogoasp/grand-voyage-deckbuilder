# Guia de Integração: Hub Web Django para Criação e Exportação de Conteúdo

Este guia fornece a arquitetura completa para criar um aplicativo Django (`deckbuilder_hub`) na sua aplicação web existente de RPG. Ele permite que seus jogadores criem cartas, inimigos e eventos de forma visual e segura, com moderação de aprovação e exportação direta para os JSONs consumidos pelo Godot Engine no **Grand Voyage Deckbuilder**.

---

## 1. Estrutura do App no Projeto Django

Dentro do seu projeto Django existente:
```bash
python manage.py startapp deckbuilder_hub
```

Adicione `'deckbuilder_hub'` no `INSTALLED_APPS` em `settings.py`.

---

## 2. Modelagem (`models.py`)

Espelha com fidelidade o schema de dados do jogo, utilizando `JSONField` para os efeitos dinâmicos interpretados pelo `EffectResolver`.

```python
# deckbuilder_hub/models.py
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Card(models.Model):
    TYPE_CHOICES = [
        ("attack", "Ataque"),
        ("skill", "Habilidade"),
    ]
    RARITY_CHOICES = [
        ("starter", "Inicial"),
        ("common", "Comum"),
        ("uncommon", "Incomum"),
        ("rare", "Rara"),
    ]
    SOURCE_CHOICES = [
        ("starter_deck", "Deck Inicial"),
        ("combat_reward", "Recompensa de Combate"),
        ("training", "Treinamento em Cidade"),
        ("crew", "Tripulação"),
        ("devil_fruit", "Akuma no Mi"),
        ("haki_training", "Treinamento de Haki"),
    ]

    slug_id = models.SlugField(
        max_length=50,
        unique=True,
        help_text="ID único em snake_case (ex: cutlass_slash, brace_impact)",
    )
    name = models.CharField("Nome da Carta", max_length=100)
    description = models.TextField("Descrição do Efeito")
    cost = models.PositiveIntegerField("Custo de Energia", default=1)
    card_type = models.CharField("Tipo", max_length=20, choices=TYPE_CHOICES, default="attack")
    rarity = models.CharField("Raridade", max_length=20, choices=RARITY_CHOICES, default="common")
    source = models.CharField("Origem", max_length=30, choices=SOURCE_CHOICES, default="combat_reward")
    
    # Efeitos resolvidos pelo EffectResolver do Godot
    # Exemplo: [{"type": "damage", "value": 8, "target": "enemy"}]
    effects = models.JSONField("Efeitos (JSON)", default=list, blank=True)

    # Moderação e Autoria
    author = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Autor")
    is_approved = models.BooleanField("Aprovado para o Jogo?", default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Carta"
        verbose_name_plural = "Cartas"

    def __str__(self):
        return f"{self.name} ({self.slug_id})"

    def to_game_dict(self):
        """Converte a instância para o formato exato esperado por cards.json."""
        return {
            "id": self.slug_id,
            "name": self.name,
            "description": self.description,
            "cost": self.cost,
            "type": self.card_type,
            "rarity": self.rarity,
            "source": self.source,
            "effects": self.effects
        }


class Enemy(models.Model):
    CATEGORY_CHOICES = [
        ("common", "Inimigo Comum"),
        ("elite", "Inimigo de Elite"),
        ("boss", "Chefe de Setor"),
    ]

    slug_id = models.SlugField(max_length=50, unique=True, help_text="Ex: marine_recruit, bandit_sailor")
    name = models.CharField("Nome do Inimigo", max_length=100)
    category = models.CharField("Categoria", max_length=20, choices=CATEGORY_CHOICES, default="common")
    max_hp = models.PositiveIntegerField("HP Máximo", default=35)
    
    # Recompensas
    gold_min = models.PositiveIntegerField("Ouro Mínimo", default=10)
    gold_max = models.PositiveIntegerField("Ouro Máximo", default=20)
    bounty = models.PositiveIntegerField("Recompensa de Bounty", default=5)

    # Intenções com peso de rolagem
    intent_pool = models.JSONField("Pool de Intenções (JSON)", default=list, blank=True)

    author = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    is_approved = models.BooleanField("Aprovado para o Jogo?", default=False)

    class Meta:
        verbose_name = "Inimigo"
        verbose_name_plural = "Inimigos"

    def __str__(self):
        return f"{self.name} ({self.slug_id})"

    def to_game_dict(self):
        data = {
            "id": self.slug_id,
            "name": self.name,
            "max_hp": self.max_hp,
            "intent_pool": self.intent_pool,
            "rewards": {
                "gold_min": self.gold_min,
                "gold_max": self.gold_max,
                "bounty": self.bounty
            }
        }
        if self.category == "boss":
            data["category"] = "boss"
        return data
```

---

## 3. Configuração do Django Admin (`admin.py`) com Ação de Exportação

O Django Admin nativo serve como o seu painel de controle do Mestre para aprovar e exportar conteúdos em um clique:

```python
# deckbuilder_hub/admin.py
import json
from django.contrib import admin
from django.http import HttpResponse
from .models import Card, Enemy


@admin.action(description="Exportar cartas selecionadas para cards.json")
def export_cards_json(modeladmin, request, queryset):
    approved_cards = queryset.filter(is_approved=True)
    export_dict = {}
    for card in approved_cards:
        export_dict[card.slug_id] = card.to_game_dict()

    json_str = json.dumps(export_dict, indent=2, ensure_ascii=False)
    response = HttpResponse(json_str, content_type="application/json; charset=utf-8")
    response["Content-Disposition"] = 'attachment; filename="cards.json"'
    return response


@admin.action(description="Aprovar itens selecionados para o jogo")
def approve_selected(modeladmin, request, queryset):
    queryset.update(is_approved=True)


@admin.register(Card)
class CardAdmin(admin.ModelAdmin):
    list_display = ["name", "slug_id", "card_type", "cost", "rarity", "source", "author", "is_approved"]
    list_filter = ["card_type", "rarity", "source", "is_approved"]
    search_fields = ["name", "slug_id", "description"]
    actions = [approve_selected, export_cards_json]


@admin.register(Enemy)
class EnemyAdmin(admin.ModelAdmin):
    list_display = ["name", "slug_id", "category", "max_hp", "author", "is_approved"]
    list_filter = ["category", "is_approved"]
    search_fields = ["name", "slug_id"]
    actions = [approve_selected]
```

---

## 4. Visualização Web para Jogadores Criarem Cartas com Preview em Tempo Real

Crie uma view protegida por login para seus amigos enviarem ideias:

### Formulário (`forms.py`)
```python
# deckbuilder_hub/forms.py
from django import forms
from .models import Card

class CardProposalForm(forms.ModelForm):
    class Meta:
        model = Card
        fields = ["slug_id", "name", "cost", "card_type", "rarity", "source", "description"]
        widgets = {
            "description": forms.Textarea(attrs={"rows": 3}),
        }
```

### View (`views.py`)
```python
# deckbuilder_hub/views.py
import json
from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from .forms import CardProposalForm
from .models import Card


@login_required
def create_card_view(request):
    if request.method == "POST":
        form = CardProposalForm(request.POST)
        if form.is_valid():
            card = form.save(commit=False)
            card.author = request.user
            card.is_approved = False  # Aguarda validação do mestre

            # Processamento básico dos efeitos submetidos
            raw_effects = request.POST.get("effects_json", "[]")
            try:
                card.effects = json.loads(raw_effects)
            except Exception:
                card.effects = []

            card.save()
            return redirect("deckbuilder_hub:card_list")
    else:
        form = CardProposalForm()

    return render(request, "deckbuilder_hub/create_card.html", {"form": form})


def export_all_approved_cards_api(request):
    """Endpoint caso deseje puxar os JSONs automaticamente via script/curl."""
    cards = Card.objects.filter(is_approved=True)
    data = {c.slug_id: c.to_game_dict() for c in cards}
    return JsonResponse(data, json_dumps_params={"indent": 2, "ensure_ascii": False})
```

---

## 5. Template HTML com Preview Visual Dinâmico (`create_card.html`)

Este template estiliza um cartão interativo que se atualiza em tempo real enquanto seu amigo digita:

```html
<!-- deckbuilder_hub/templates/deckbuilder_hub/create_card.html -->
<!DOCTYPE html>
<html lang="pt-br">
<head>
  <meta charset="UTF-8">
  <title>Criador de Cartas - Grand Voyage</title>
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #1a1e24; color: #fff; padding: 30px; }
    .container { display: flex; gap: 40px; max-width: 1000px; margin: 0 auto; }
    .form-panel { flex: 1; background: #252b34; padding: 24px; border-radius: 8px; }
    .preview-panel { width: 260px; display: flex; flex-direction: column; align-items: center; }
    
    /* Mock do CardView do Godot */
    .card-view {
      width: 180px; height: 260px; background: #2f3846; border: 2px solid #5a6e85;
      border-radius: 8px; padding: 12px; display: flex; flex-direction: column;
      box-shadow: 0 8px 16px rgba(0,0,0,0.4); box-sizing: border-box;
    }
    .card-title { font-weight: bold; font-size: 15px; margin-bottom: 4px; border-bottom: 1px solid #48586c; padding-bottom: 4px; }
    .card-cost { font-size: 13px; color: #ffcc00; margin-bottom: 8px; }
    .card-type { font-size: 11px; text-transform: uppercase; color: #7cbbf2; margin-bottom: 8px; }
    .card-desc { font-size: 13px; color: #d0d7de; flex: 1; overflow-y: auto; }
    
    input, select, textarea, button { width: 100%; padding: 8px; margin-top: 6px; margin-bottom: 14px; border-radius: 4px; border: 1px solid #444; background: #181c22; color: #fff; box-sizing: border-box; }
    button { background: #2d72d2; border: none; cursor: pointer; font-weight: bold; }
    button:hover { background: #3b82f6; }
  </style>
</head>
<body>

<div class="container">
  <div class="form-panel">
    <h2>Sugerir Nova Carta</h2>
    <form method="post" id="cardForm">
      {% csrf_token %}
      {{ form.as_p }}

      <label>Efeito Pré-configurado:</label>
      <div style="display: flex; gap: 8px;">
        <select id="effectType">
          <option value="damage">Dano</option>
          <option value="block">Bloqueio</option>
          <option value="draw">Comprar Cartas</option>
          <option value="gain_energy">Ganhar Energia</option>
          <option value="heal">Curar</option>
          <option value="intangible">Intangibilidade</option>
        </select>
        <input type="number" id="effectValue" placeholder="Valor" value="6" style="width: 90px;">
        <button type="button" onclick="addEffect()" style="width: 120px;">+ Adicionar</button>
      </div>

      <input type="hidden" name="effects_json" id="effectsJson" value="[]">
      <div id="effectsList" style="font-size: 12px; color: #9ab; margin-bottom: 15px;">Efeitos: []</div>

      <button type="submit">Enviar Proposta de Carta</button>
    </form>
  </div>

  <div class="preview-panel">
    <h3>Preview em Jogo</h3>
    <div class="card-view">
      <div class="card-title" id="prevTitle">Nome da Carta</div>
      <div class="card-cost" id="prevCost">Custo: 1</div>
      <div class="card-type" id="prevType">[ATAQUE]</div>
      <div class="card-desc" id="prevDesc">Descrição do efeito aqui...</div>
    </div>
  </div>
</div>

<script>
  const nameInput = document.getElementById('id_name');
  const costInput = document.getElementById('id_cost');
  const typeInput = document.getElementById('id_card_type');
  const descInput = document.getElementById('id_description');

  function updatePreview() {
    document.getElementById('prevTitle').innerText = nameInput.value || "Nome da Carta";
    document.getElementById('prevCost').innerText = "Custo: " + (costInput.value || "1");
    document.getElementById('prevType').innerText = "[" + (typeInput.options[typeInput.selectedIndex]?.text || "ATAQUE") + "]";
    document.getElementById('prevDesc').innerText = descInput.value || "Descrição do efeito aqui...";
  }

  [nameInput, costInput, typeInput, descInput].forEach(el => el && el.addEventListener('input', updatePreview));

  let currentEffects = [];
  function addEffect() {
    const t = document.getElementById('effectType').value;
    const v = parseInt(document.getElementById('effectValue').value) || 0;
    const target = (t === 'damage') ? 'enemy' : 'player';
    currentEffects.push({ type: t, value: v, target: target });
    document.getElementById('effectsJson').value = JSON.stringify(currentEffects);
    document.getElementById('effectsList').innerText = "Efeitos: " + JSON.stringify(currentEffects);
  }
</script>

</body>
</html>
```

---

## 6. Sincronização com o Repositório do Godot

Quando você aprovar cartas pelo Django Admin, você pode exportar o `cards.json` de três formas simples:

1. **Manual (Mais seguro e imediato):**
   - No Admin, selecione as cartas aprovadas -> Ação: *"Exportar cartas selecionadas para cards.json"*.
   - Salve o arquivo diretamente na pasta `grand-voyage-deckbuilder/data/cards/cards.json`.

2. **Via Comando de Gerenciamento (`manage.py export_game_data`):**
   - Crie um comando personalizado no Django que grava diretamente no caminho do repositório local:
   ```python
   # deckbuilder_hub/management/commands/export_game_data.py
   import json
   from django.core.management.base import BaseCommand
   from deckbuilder_hub.models import Card

   class Command(BaseCommand):
       help = "Exporta cards aprovados para o projeto Godot"

       def handle(self, *args, **options):
           cards = Card.objects.filter(is_approved=True)
           data = {c.slug_id: c.to_game_dict() for c in cards}
           with open("/caminho/para/grand-voyage-deckbuilder/data/cards/cards.json", "w", encoding="utf-8") as f:
               json.dump(data, f, indent=2, ensure_ascii=False)
           self.stdout.write(self.style.SUCCESS(f"{cards.count()} cartas exportadas com sucesso!"))
   ```
