#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Демонстраційний парсер tabletki.ua (без зовнішніх залежностей)
Показує структуру та логіку роботи парсера
"""

import json
import csv
import time
import logging
from typing import List, Dict, Optional
from dataclasses import dataclass
import random
import re


@dataclass
class PharmacyData:
    """Структура даних для аптеки"""
    pharmacy_name: str
    address: str
    product_name: str
    price: str
    availability: str
    url: str
    city: str = ""
    phone: str = ""


class DemoTabletkiParser:
    """Демонстраційний парсер для tabletki.ua"""
    
    def __init__(self, delay_range: tuple = (1, 3)):
        """Ініціалізація парсера"""
        self.base_url = "https://tabletki.ua"
        self.delay_range = delay_range
        
        # Налаштування логування
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
        
        self.data: List[PharmacyData] = []
        
        # Демонстраційні дані для тестування
        self.demo_data = self._generate_demo_data()
    
    def _generate_demo_data(self) -> List[PharmacyData]:
        """Генерація демонстраційних даних"""
        demo_pharmacies = [
            {
                "name": "Аптека АНЦ",
                "addresses": ["вул. Хрещатик, 1", "вул. Володимирська, 15", "просп. Перемоги, 25"]
            },
            {
                "name": "Аптека Копійка", 
                "addresses": ["вул. Саксаганського, 33", "бул. Лесі Українки, 7", "вул. Велика Васильківська, 12"]
            },
            {
                "name": "Фармація",
                "addresses": ["вул. Горького, 8", "просп. Науки, 45", "вул. Антоновича, 18"]
            },
            {
                "name": "Біла Ромашка",
                "addresses": ["вул. Бориспільська, 5", "просп. Оболонський, 22", "вул. Ревуцького, 9"]
            }
        ]
        
        demo_products = [
            {"name": "Парацетамол таблетки 500мг №10", "base_price": 15.50},
            {"name": "Ібупрофен капсули 200мг №20", "base_price": 28.75},
            {"name": "Аспірин таблетки 325мг №30", "base_price": 22.30},
            {"name": "Нурофен сироп 100мл", "base_price": 87.60},
            {"name": "Цитрамон таблетки №6", "base_price": 8.90},
            {"name": "Анальгін таблетки 500мг №10", "base_price": 12.45},
            {"name": "Амоксицилін капсули 250мг №16", "base_price": 45.20},
            {"name": "Лоратадин таблетки 10мг №10", "base_price": 19.80}
        ]
        
        data = []
        
        for pharmacy in demo_pharmacies:
            for address in pharmacy["addresses"]:
                for product in demo_products:
                    # Варіювання цін ±20%
                    price_variation = random.uniform(0.8, 1.2)
                    final_price = product["base_price"] * price_variation
                    
                    availability_options = ["В наявності", "Закінчується", "Під замовлення"]
                    
                    pharmacy_data = PharmacyData(
                        pharmacy_name=pharmacy["name"],
                        address=address,
                        product_name=product["name"],
                        price=f"{final_price:.2f} грн",
                        availability=random.choice(availability_options),
                        url=f"{self.base_url}/product/{product['name'].lower().replace(' ', '-')}",
                        city="Київ",
                        phone=f"+380{random.randint(441234567, 501234567)}"
                    )
                    
                    data.append(pharmacy_data)
        
        return data
    
    def _random_delay(self):
        """Випадкова затримка між запитами"""
        delay = random.uniform(*self.delay_range)
        self.logger.info(f"Затримка {delay:.1f} секунд...")
        time.sleep(delay)
    
    def search_specific_product(self, product_name: str, city: str = "Київ") -> List[PharmacyData]:
        """Пошук конкретного товару (демо версія)"""
        self.logger.info(f"Пошук товару: {product_name} у місті {city}")
        
        # Імітація затримки мережевого запиту
        self._random_delay()
        
        # Фільтрація демонстраційних даних
        results = []
        search_terms = product_name.lower().split()
        
        for item in self.demo_data:
            item_name_lower = item.product_name.lower()
            if any(term in item_name_lower for term in search_terms):
                if city.lower() in item.city.lower() or not city:
                    results.append(item)
        
        self.logger.info(f"Знайдено {len(results)} результатів")
        return results[:10]  # Обмежуємо кількість результатів
    
    def get_popular_products(self) -> List[PharmacyData]:
        """Отримання популярних товарів (демо версія)"""
        self.logger.info("Отримання популярних товарів...")
        
        self._random_delay()
        
        # Вибираємо випадкові товари як "популярні"
        popular_count = random.randint(15, 25)
        results = random.sample(self.demo_data, min(popular_count, len(self.demo_data)))
        
        self.logger.info(f"Знайдено {len(results)} популярних товарів")
        return results
    
    def analyze_prices(self, product_name: str) -> Dict:
        """Аналіз цін на товар"""
        self.logger.info(f"Аналіз цін для: {product_name}")
        
        results = self.search_specific_product(product_name)
        
        if not results:
            return {}
        
        prices = []
        for item in results:
            try:
                # Витягуємо числове значення ціни
                price_str = item.price.replace('грн', '').replace(',', '.').strip()
                price_num = float(''.join(filter(lambda x: x.isdigit() or x == '.', price_str)))
                prices.append(price_num)
            except ValueError:
                continue
        
        if not prices:
            return {}
        
        analysis = {
            'product_name': product_name,
            'min_price': min(prices),
            'max_price': max(prices),
            'avg_price': sum(prices) / len(prices),
            'price_count': len(prices),
            'pharmacies_count': len(set(item.pharmacy_name for item in results)),
            'price_difference': max(prices) - min(prices)
        }
        
        return analysis
    
    def save_to_csv(self, filename: str = "demo_tabletki_data.csv"):
        """Збереження у CSV"""
        if not self.data:
            self.logger.warning("Немає даних для збереження")
            return
        
        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['pharmacy_name', 'address', 'product_name', 'price', 'availability', 'phone', 'url']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            writer.writeheader()
            for item in self.data:
                writer.writerow({
                    'pharmacy_name': item.pharmacy_name,
                    'address': item.address,
                    'product_name': item.product_name,
                    'price': item.price,
                    'availability': item.availability,
                    'phone': item.phone,
                    'url': item.url
                })
        
        self.logger.info(f"Дані збережено у файл {filename}")
    
    def save_to_json(self, filename: str = "demo_tabletki_data.json"):
        """Збереження у JSON"""
        if not self.data:
            self.logger.warning("Немає даних для збереження")
            return
        
        data_dict = []
        for item in self.data:
            data_dict.append({
                'pharmacy_name': item.pharmacy_name,
                'address': item.address,
                'product_name': item.product_name,
                'price': item.price,
                'availability': item.availability,
                'phone': item.phone,
                'url': item.url
            })
        
        with open(filename, 'w', encoding='utf-8') as jsonfile:
            json.dump(data_dict, jsonfile, ensure_ascii=False, indent=2)
        
        self.logger.info(f"Дані збережено у файл {filename}")
    
    def get_statistics(self) -> Dict:
        """Статистика зібраних даних"""
        if not self.data:
            return {}
        
        pharmacies = set(item.pharmacy_name for item in self.data)
        products = set(item.product_name for item in self.data)
        
        return {
            'total_records': len(self.data),
            'unique_pharmacies': len(pharmacies),
            'unique_products': len(products),
            'pharmacies_list': sorted(list(pharmacies)),
            'products_list': sorted(list(products))
        }


def demo_search_example():
    """Демонстрація пошуку товару"""
    print("\n=== Демо 1: Пошук товару ===")
    
    parser = DemoTabletkiParser(delay_range=(0.5, 1))
    
    # Пошук Парацетамолу
    results = parser.search_specific_product("Парацетамол")
    parser.data = results
    
    print(f"Знайдено {len(results)} аптек з Парацетамолом:")
    
    for i, item in enumerate(results[:5], 1):
        print(f"{i}. {item.pharmacy_name}")
        print(f"   Адреса: {item.address}")
        print(f"   Ціна: {item.price}")
        print(f"   Наявність: {item.availability}")
        print(f"   Телефон: {item.phone}")
        print()
    
    # Збереження результатів
    parser.save_to_csv("demo_paracetamol.csv")
    print("Результати збережено у demo_paracetamol.csv")


def demo_price_analysis():
    """Демонстрація аналізу цін"""
    print("\n=== Демо 2: Аналіз цін ===")
    
    parser = DemoTabletkiParser()
    
    products_to_analyze = ["Парацетамол", "Ібупрофен", "Нурофен"]
    
    for product in products_to_analyze:
        analysis = parser.analyze_prices(product)
        
        if analysis:
            print(f"\n📊 Аналіз цін на {product}:")
            print(f"   Мінімальна ціна: {analysis['min_price']:.2f} грн")
            print(f"   Максимальна ціна: {analysis['max_price']:.2f} грн")
            print(f"   Середня ціна: {analysis['avg_price']:.2f} грн")
            print(f"   Різниця цін: {analysis['price_difference']:.2f} грн")
            print(f"   Кількість пропозицій: {analysis['price_count']}")
            print(f"   Кількість аптек: {analysis['pharmacies_count']}")


def demo_popular_products():
    """Демонстрація популярних товарів"""
    print("\n=== Демо 3: Популярні товари ===")
    
    parser = DemoTabletkiParser()
    
    popular = parser.get_popular_products()
    parser.data = popular
    
    # Аналіз по аптеках
    pharmacy_count = {}
    for item in popular:
        if item.pharmacy_name in pharmacy_count:
            pharmacy_count[item.pharmacy_name] += 1
        else:
            pharmacy_count[item.pharmacy_name] = 1
    
    print("Топ аптек за кількістю популярних товарів:")
    sorted_pharmacies = sorted(pharmacy_count.items(), key=lambda x: x[1], reverse=True)
    
    for i, (name, count) in enumerate(sorted_pharmacies, 1):
        print(f"{i}. {name}: {count} товарів")
    
    # Статистика
    stats = parser.get_statistics()
    print(f"\nСтатистика:")
    print(f"Загалом записів: {stats['total_records']}")
    print(f"Унікальних аптек: {stats['unique_pharmacies']}")
    print(f"Унікальних товарів: {stats['unique_products']}")
    
    # Збереження
    parser.save_to_json("demo_popular_products.json")
    print("\nРезультати збережено у demo_popular_products.json")


def main():
    """Головна демонстраційна функція"""
    print("🏥 Демонстрація парсера tabletki.ua")
    print("=" * 50)
    print("⚠️  Це демонстраційна версія з тестовими даними")
    print("Для роботи з реальним сайтом використовуйте:")
    print("- tabletki_simple_parser.py (без Selenium)")
    print("- tabletki_parser.py (з Selenium)")
    print("=" * 50)
    
    demos = [
        ("Пошук товару", demo_search_example),
        ("Аналіз цін", demo_price_analysis),
        ("Популярні товари", demo_popular_products),
        ("Запустити всі демо", "all")
    ]
    
    print("\nДоступні демонстрації:")
    for i, (title, _) in enumerate(demos, 1):
        print(f"{i}. {title}")
    
    try:
        choice = input(f"\nВиберіть демо (1-{len(demos)}): ").strip()
        choice_num = int(choice)
        
        if 1 <= choice_num <= len(demos):
            if choice_num == len(demos):  # Запустити всі
                for title, func in demos[:-1]:
                    print(f"\n{'='*60}")
                    print(f"Запускаємо: {title}")
                    print('='*60)
                    func()
            else:
                title, func = demos[choice_num - 1]
                func()
        else:
            print("Невірний вибір")
            
    except ValueError:
        print("Введіть номер демонстрації")
    except KeyboardInterrupt:
        print("\n\nДемо перервано")
    
    print("\n" + "="*50)
    print("Демонстрацію завершено!")
    print("\nФайли створено:")
    print("- demo_paracetamol.csv")
    print("- demo_popular_products.json")


if __name__ == "__main__":
    main()