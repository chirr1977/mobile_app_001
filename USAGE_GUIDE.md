# Швидкий посібник використання парсера tabletki.ua

## 🚀 Швидкий старт

### 1. Демонстраційна версія (без інтернету)
```bash
python3 demo_parser.py
```
Показує роботу парсера з тестовими даними.

### 2. Спрощена версія (тільки HTTP запити)
```bash
python3 tabletki_simple_parser.py
```

### 3. Повна версія (з Selenium)
```bash
python3 tabletki_parser.py
```

### 4. Приклади використання
```bash
python3 example_usage.py
```

## 📋 Основні можливості

### Збір даних
- **Назва аптеки** - повна назва мережі
- **Адреса** - точна адреса філії
- **Товар** - назва препарату
- **Ціна** - вартість в грн
- **Наявність** - статус товару
- **Телефон** - контакт аптеки

### Формати експорту
- **CSV** - для Excel та аналітики
- **JSON** - для інтеграції з іншими системами

## 🔧 Використання в коді

### Базовий приклад
```python
from tabletki_simple_parser import SimpleTabletkiParser

# Створення парсера
parser = SimpleTabletkiParser()

# Пошук товару
results = parser.search_specific_product("Парацетамол", "Київ")

# Збереження результатів
parser.data = results
parser.save_to_csv("paracetamol_results.csv")

# Показ результатів
for item in results[:5]:
    print(f"{item.pharmacy_name} - {item.price}")
```

### Аналіз цін
```python
# Порівняння цін різних ліків
medicines = ["Парацетамол", "Ібупрофен", "Аспірин"]

for medicine in medicines:
    results = parser.search_specific_product(medicine)
    prices = [float(item.price.replace('грн', '').strip()) 
              for item in results if 'грн' in item.price]
    
    if prices:
        print(f"{medicine}:")
        print(f"  Мін: {min(prices):.2f} грн")
        print(f"  Макс: {max(prices):.2f} грн")
        print(f"  Серед: {sum(prices)/len(prices):.2f} грн")
```

## ⚙️ Налаштування

### Затримки між запитами
```python
# Швидко (може заблокувати)
parser = SimpleTabletkiParser(delay_range=(0.5, 1))

# Помірно (рекомендовано)
parser = SimpleTabletkiParser(delay_range=(1, 3))

# Повільно (найбезпечніше)
parser = SimpleTabletkiParser(delay_range=(3, 5))
```

### Selenium опції
```python
# Фоновий режим
parser = TabletkiParser(headless=True)

# З показом браузера
parser = TabletkiParser(headless=False)
```

## 📊 Типові сценарії

### 1. Моніторинг цін
```python
# Щоденний моніторинг популярних ліків
daily_meds = ["Парацетамол", "Ібупрофен", "Аспірин"]

for med in daily_meds:
    results = parser.search_specific_product(med)
    filename = f"{med.lower()}_{datetime.now().strftime('%Y%m%d')}.csv"
    parser.data = results
    parser.save_to_csv(filename)
```

### 2. Пошук найдешевших аптек
```python
medicine = "Нурофен"
results = parser.search_specific_product(medicine)

# Сортування за ціною
sorted_results = sorted(results, 
    key=lambda x: float(x.price.replace('грн', '').strip()) 
    if 'грн' in x.price else 999)

print("Найдешевші пропозиції:")
for i, item in enumerate(sorted_results[:5], 1):
    print(f"{i}. {item.pharmacy_name} - {item.price}")
    print(f"   {item.address}")
```

### 3. Аналіз по районах
```python
results = parser.search_specific_product("Парацетамол")

# Групування за районами
districts = {}
for item in results:
    # Простий аналіз адреси
    if "Хрещатик" in item.address:
        district = "Центр"
    elif "Оболон" in item.address:
        district = "Оболонь"
    else:
        district = "Інший"
    
    if district not in districts:
        districts[district] = []
    districts[district].append(item)

for district, items in districts.items():
    avg_price = sum(float(item.price.replace('грн', '').strip()) 
                   for item in items if 'грн' in item.price) / len(items)
    print(f"{district}: {avg_price:.2f} грн (середня)")
```

## ⚠️ Важливі нотатки

### Обмеження
- Не більше 10-20 запитів за хвилину
- Використовуйте затримки між запитами
- Перевірте robots.txt сайту

### Помилки
- Якщо сайт заблокував - збільшіть затримки
- Якщо не знаходить дані - оновіть селектори
- Якщо Selenium не працює - використовуйте спрощену версію

### Рекомендації
- Збережіть резервну копію даних
- Використовуйте різні User-Agent
- Парсіть у непікові години
- Поважайте ресурси сайту

## 📁 Структура файлів

```
tabletki-parser/
├── demo_parser.py              # Демо без інтернету ✅
├── tabletki_simple_parser.py   # HTTP парсер ✅
├── tabletki_parser.py          # Selenium парсер ✅
├── example_usage.py            # Приклади ✅
├── setup.py                    # Установка ✅
├── requirements.txt            # Залежності ✅
├── README.md                   # Документація ✅
└── USAGE_GUIDE.md             # Цей посібник ✅
```

## 🆘 Допомога

### Часті питання

**Q: Не працює пошук?**
A: Перевірте інтернет з'єднання та спробуйте демо версію.

**Q: Selenium помилки?**
A: Встановіть ChromeDriver або використовуйте спрощену версію.

**Q: Блокує сайт?**
A: Збільшіть затримки та змініть User-Agent.

**Q: Пусті результати?**
A: Сайт міг змінити структуру, потрібно оновити селектори.

### Контакти
- Створіть Issue на GitHub
- Опишіть проблему детально
- Додайте лог помилок

---

**Успішного парсингу! 🏥💊**