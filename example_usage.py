#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Приклади використання парсерів tabletki.ua
"""

import sys
import os
from datetime import datetime

# Додаємо шлях до парсерів
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from tabletki_parser import TabletkiParser
    SELENIUM_AVAILABLE = True
except ImportError:
    SELENIUM_AVAILABLE = False
    print("Selenium не доступний, використовуємо тільки спрощений парсер")

from tabletki_simple_parser import SimpleTabletkiParser


def example_1_search_specific_medicine():
    """Приклад 1: Пошук конкретного ліки"""
    print("\n=== Приклад 1: Пошук конкретного ліки ===")
    
    # Використовуємо спрощений парсер
    parser = SimpleTabletkiParser(delay_range=(1, 2))
    
    # Пошук Парацетамолу у Києві
    medicine = "Парацетамол"
    city = "Київ"
    
    print(f"Шукаємо '{medicine}' у місті {city}...")
    
    try:
        data = parser.search_specific_product(medicine, city)
        parser.data = data
        
        if data:
            print(f"Знайдено {len(data)} аптек з цим ліками")
            
            # Показуємо перші 3 результати
            for i, item in enumerate(data[:3], 1):
                print(f"{i}. {item.pharmacy_name}")
                print(f"   Адреса: {item.address}")
                print(f"   Ціна: {item.price}")
                print(f"   Наявність: {item.availability}")
                print()
            
            # Зберігаємо у файл
            filename = f"search_{medicine.lower()}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
            parser.save_to_csv(filename)
            print(f"Результати збережено у файл: {filename}")
            
        else:
            print("Результати не знайдено")
            
    except Exception as e:
        print(f"Помилка при пошуку: {e}")


def example_2_popular_products():
    """Приклад 2: Аналіз популярних товарів"""
    print("\n=== Приклад 2: Аналіз популярних товарів ===")
    
    parser = SimpleTabletkiParser()
    
    print("Парсимо популярні товари...")
    
    try:
        data = parser.parse_popular_products()
        parser.data = data
        
        if data:
            print(f"Знайдено {len(data)} записів популярних товарів")
            
            # Аналіз по аптеках
            pharmacies = {}
            for item in data:
                if item.pharmacy_name in pharmacies:
                    pharmacies[item.pharmacy_name] += 1
                else:
                    pharmacies[item.pharmacy_name] = 1
            
            print("\nТоп-5 аптек за кількістю товарів:")
            sorted_pharmacies = sorted(pharmacies.items(), key=lambda x: x[1], reverse=True)
            for i, (name, count) in enumerate(sorted_pharmacies[:5], 1):
                print(f"{i}. {name}: {count} товарів")
            
            # Збереження
            filename = f"popular_products_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            parser.save_to_json(filename)
            print(f"\nРезультати збережено у файл: {filename}")
            
        else:
            print("Популярні товари не знайдено")
            
    except Exception as e:
        print(f"Помилка при парсингу популярних товарів: {e}")


def example_3_price_comparison():
    """Приклад 3: Порівняння цін на кілька ліків"""
    print("\n=== Приклад 3: Порівняння цін на кілька ліків ===")
    
    parser = SimpleTabletkiParser(delay_range=(2, 3))  # Більші затримки для стабільності
    
    medicines = ["Ібупрофен", "Нурофен", "Аспірин"]
    all_data = []
    
    for medicine in medicines:
        print(f"Шукаємо {medicine}...")
        
        try:
            data = parser.search_specific_product(medicine)
            if data:
                all_data.extend(data[:5])  # Берем перші 5 результатів
                print(f"  Знайдено {len(data)} аптек")
            else:
                print(f"  {medicine} не знайдено")
                
        except Exception as e:
            print(f"  Помилка при пошуку {medicine}: {e}")
    
    if all_data:
        parser.data = all_data
        
        print(f"\nЗагалом знайдено {len(all_data)} записів")
        
        # Аналіз цін
        prices = {}
        for item in all_data:
            if item.price and 'грн' in item.price:
                try:
                    # Витягуємо числове значення ціни
                    price_str = item.price.replace('грн', '').replace(',', '.').strip()
                    price_num = float(''.join(filter(lambda x: x.isdigit() or x == '.', price_str)))
                    
                    if item.product_name not in prices:
                        prices[item.product_name] = []
                    prices[item.product_name].append(price_num)
                    
                except ValueError:
                    continue
        
        print("\nАналіз цін:")
        for product, price_list in prices.items():
            if price_list:
                min_price = min(price_list)
                max_price = max(price_list)
                avg_price = sum(price_list) / len(price_list)
                
                print(f"{product}:")
                print(f"  Мін. ціна: {min_price:.2f} грн")
                print(f"  Макс. ціна: {max_price:.2f} грн")
                print(f"  Серед. ціна: {avg_price:.2f} грн")
                print(f"  Кіл-ть пропозицій: {len(price_list)}")
                print()
        
        # Збереження
        filename = f"price_comparison_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        parser.save_to_csv(filename)
        print(f"Результати збережено у файл: {filename}")


def example_4_selenium_advanced():
    """Приклад 4: Розширений парсинг з Selenium (якщо доступний)"""
    if not SELENIUM_AVAILABLE:
        print("\n=== Приклад 4: Selenium не доступний ===")
        print("Встановіть selenium для використання розширеного функціоналу")
        return
    
    print("\n=== Приклад 4: Розширений парсинг з Selenium ===")
    
    parser = TabletkiParser(headless=True, delay_range=(2, 4))
    
    print("Парсинг по категоріях...")
    
    try:
        # Парсинг 2 категорій для демонстрації
        data = parser.parse_categories(max_categories=2)
        
        if data:
            print(f"Знайдено {len(data)} записів")
            
            # Статистика
            stats = parser.get_statistics()
            print(f"\nСтатистика:")
            print(f"Загалом записів: {stats['total_records']}")
            print(f"Унікальних аптек: {stats['unique_pharmacies']}")
            print(f"Унікальних товарів: {stats['unique_products']}")
            
            # Показуємо список аптек
            print(f"\nЗнайдені аптеки:")
            for i, pharmacy in enumerate(stats['pharmacies_list'][:10], 1):
                print(f"{i}. {pharmacy}")
            
            # Збереження в обох форматах
            csv_filename = f"categories_selenium_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
            json_filename = f"categories_selenium_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            
            parser.save_to_csv(csv_filename)
            parser.save_to_json(json_filename)
            
            print(f"\nРезультати збережено:")
            print(f"CSV: {csv_filename}")
            print(f"JSON: {json_filename}")
            
        else:
            print("Дані не знайдено")
            
    except Exception as e:
        print(f"Помилка при парсингу з Selenium: {e}")


def main():
    """Головна функція з вибором прикладів"""
    print("🏥 Приклади використання парсера tabletki.ua")
    print("=" * 50)
    
    examples = [
        ("Пошук конкретного ліки", example_1_search_specific_medicine),
        ("Аналіз популярних товарів", example_2_popular_products),
        ("Порівняння цін на кілька ліків", example_3_price_comparison),
        ("Розширений парсинг з Selenium", example_4_selenium_advanced),
        ("Запустити всі приклади", "all")
    ]
    
    print("\nДоступні приклади:")
    for i, (title, _) in enumerate(examples, 1):
        print(f"{i}. {title}")
    
    try:
        choice = input(f"\nВиберіть приклад (1-{len(examples)}): ").strip()
        choice_num = int(choice)
        
        if 1 <= choice_num <= len(examples):
            if choice_num == len(examples):  # Запустити всі
                for title, func in examples[:-1]:
                    if callable(func):
                        print(f"\n{'='*60}")
                        print(f"Запускаємо: {title}")
                        print('='*60)
                        func()
            else:
                title, func = examples[choice_num - 1]
                if callable(func):
                    func()
        else:
            print("Невірний вибір")
            
    except ValueError:
        print("Введіть номер прикладу")
    except KeyboardInterrupt:
        print("\n\nПарсинг перервано користувачем")
    except Exception as e:
        print(f"Помилка: {e}")
    
    print("\n" + "="*50)
    print("Приклади завершено!")


if __name__ == "__main__":
    main()