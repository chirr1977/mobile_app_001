# Парсер сайту tabletki.ua

Проект для збору даних з сайту tabletki.ua - інформації про аптеки, адреси, товари та ціни на фармацевтичні препарати в Україні.

## 🚀 Особливості

- **Два режими роботи**: з Selenium (повний функціонал) та без (спрощений)
- **Збір даних за параметрами**: аптека, адреса, товар, ціна
- **Експорт даних**: CSV та JSON формати
- **Інтелектуальні затримки**: запобігання блокування
- **Детальне логування**: відстеження процесу парсингу
- **Підтримка міст**: можливість вибору міста для пошуку

## 📋 Зібрані дані

- **Назва аптеки** - повна назва аптечної мережі
- **Адреса** - точна адреса аптеки
- **Товар** - назва фармацевтичного препарату
- **Ціна** - вартість товару в аптеці
- **Наявність** - статус наявності товару
- **Телефон** - контактний номер аптеки (якщо доступний)
- **URL** - посилання на сторінку товару

## 🛠 Встановлення

### 1. Клонування репозиторію
```bash
git clone https://github.com/yourusername/tabletki-parser.git
cd tabletki-parser
```

### 2. Встановлення залежностей
```bash
pip install -r requirements.txt
```

### 3. Встановлення ChromeDriver (для Selenium версії)
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install chromium-chromedriver

# Windows - завантажити з https://chromedriver.chromium.org/
# MacOS
brew install chromedriver
```

## 🔧 Використання

### Повний парсер (з Selenium)

```python
from tabletki_parser import TabletkiParser

# Ініціалізація парсера
parser = TabletkiParser(headless=True)

# Пошук конкретного товару
data = parser.search_specific_product("Парацетамол", "Київ")

# Парсинг по категоріям
data = parser.parse_categories(max_categories=3)

# Збереження даних
parser.save_to_csv("results.csv")
parser.save_to_json("results.json")

# Статистика
stats = parser.get_statistics()
print(f"Знайдено аптек: {stats['unique_pharmacies']}")
```

### Спрощений парсер (без Selenium)

```python
from tabletki_simple_parser import SimpleTabletkiParser

# Ініціалізація
parser = SimpleTabletkiParser()

# Пошук товару
data = parser.search_specific_product("Нурофен", "Львів")

# Парсинг популярних товарів
data = parser.parse_popular_products()

# Збереження
parser.save_to_csv("simple_results.csv")
```

### Запуск з командного рядка

```bash
# Повний парсер
python tabletki_parser.py

# Спрощений парсер
python tabletki_simple_parser.py
```

## 📊 Приклад виводу

### CSV формат
```csv
pharmacy_name,address,product_name,price,availability,phone,url
Аптека АНЦ,вул. Хрещатик 1,Парацетамол 500мг,25.50 грн,В наявності,+380441234567,https://tabletki.ua/product/1
```

### JSON формат
```json
[
  {
    "pharmacy_name": "Аптека АНЦ",
    "address": "вул. Хрещатик 1",
    "product_name": "Парацетамол 500мг",
    "price": "25.50 грн",
    "availability": "В наявності",
    "phone": "+380441234567",
    "url": "https://tabletki.ua/product/1"
  }
]
```

## ⚙️ Налаштування

### Конфігурація парсера

```python
# Налаштування затримок (в секундах)
parser = TabletkiParser(
    headless=True,          # Фоновий режим браузера
    delay_range=(1, 3)      # Затримка між запитами
)

# Для спрощеного парсера
parser = SimpleTabletkiParser(
    delay_range=(2, 5)      # Більші затримки для стабільності
)
```

### Змінні оточення (опціонально)

Створіть файл `.env`:
```
DELAY_MIN=1
DELAY_MAX=3
BASE_URL=https://tabletki.ua
HEADLESS=true
LOG_LEVEL=INFO
```

## 🧪 Тестування

```bash
# Запуск тестів
python -m pytest tests/

# Тест основного функціоналу
python test_parser.py
```

## 📁 Структура проекту

```
tabletki-parser/
├── tabletki_parser.py          # Основний парсер з Selenium
├── tabletki_simple_parser.py   # Спрощений парсер
├── requirements.txt            # Залежності
├── README.md                  # Документація
├── .env.example              # Приклад конфігурації
├── examples/                 # Приклади використання
│   ├── basic_usage.py
│   └── advanced_usage.py
└── tests/                   # Тести
    ├── test_parser.py
    └── test_simple_parser.py
```

## 🔍 Приклади використання

### 1. Пошук антибіотиків у Києві

```python
parser = TabletkiParser()
data = parser.search_specific_product("Амоксицилін", "Київ")
parser.data = data
parser.save_to_csv("antibiotics_kyiv.csv")
```

### 2. Моніторинг цін на популярні ліки

```python
medications = ["Парацетамол", "Ібупрофен", "Аспірин"]
all_data = []

for med in medications:
    data = parser.search_specific_product(med)
    all_data.extend(data)

parser.data = all_data
parser.save_to_json("price_monitoring.json")
```

### 3. Аналіз по категоріях

```python
# Парсинг основних категорій ліків
data = parser.parse_categories(max_categories=5)

# Статистика
stats = parser.get_statistics()
print(f"Загалом записів: {stats['total_records']}")
print(f"Унікальних аптек: {stats['unique_pharmacies']}")
print(f"Унікальних товарів: {stats['unique_products']}")
```

## ⚠️ Важливі примітки

### Обмеження та рекомендації

1. **Повага до сайту**: використовуйте розумні затримки між запитами
2. **Правові аспекти**: перевірте robots.txt та умови використання
3. **Стабільність**: сайт може змінювати структуру, потрібні оновлення парсера
4. **Ресурси**: Selenium версія використовує більше ресурсів

### Обробка помилок

Парсер має вбудовану обробку основних помилок:
- Тайм-аути запитів
- Помилки мережі
- Зміни в структурі сайту
- Блокування за IP

### Оптимізація продуктивності

```python
# Для великих обсягів даних
parser = TabletkiParser(
    headless=True,
    delay_range=(2, 4)  # Збільшені затримки
)

# Обмеження кількості товарів
products = parser.search_products(query)[:10]  # Перші 10
```

## 🤝 Внесок у проект

1. Fork проекту
2. Створіть feature branch (`git checkout -b feature/amazing-feature`)
3. Commit змін (`git commit -m 'Add amazing feature'`)
4. Push до branch (`git push origin feature/amazing-feature`)
5. Відкрийте Pull Request

## 📝 Ліцензія

Цей проект має ліцензію MIT - дивіться файл [LICENSE](LICENSE) для деталей.

## 🆘 Підтримка

Якщо у вас виникли проблеми:

1. Перевірте [Issues](https://github.com/yourusername/tabletki-parser/issues)
2. Створіть нове Issue з детальним описом
3. Додайте лог помилок та версію Python

## 📈 Майбутні покращення

- [ ] Підтримка проксі
- [ ] Асинхронний парсинг
- [ ] GUI інтерфейс
- [ ] Планувальник завдань
- [ ] Інтеграція з базами даних
- [ ] API для віддаленого доступу
- [ ] Моніторинг змін цін
- [ ] Telegram бот для сповіщень

## 📧 Контакти

- Email: your.email@example.com
- Telegram: @yourusername
- LinkedIn: [your-profile](https://linkedin.com/in/your-profile)

---

**Зроблено з ❤️ для української фарм-спільноти**