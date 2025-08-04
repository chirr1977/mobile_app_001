#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Спрощений парсер сайту tabletki.ua (без Selenium)
Використовує requests + BeautifulSoup
"""

import requests
import json
import csv
import time
import logging
from bs4 import BeautifulSoup
from typing import List, Dict, Optional
from dataclasses import dataclass
from urllib.parse import urljoin, urlparse, quote
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


class SimpleTabletkiParser:
    """Спрощений парсер для tabletki.ua без Selenium"""
    
    def __init__(self, delay_range: tuple = (1, 3)):
        """Ініціалізація парсера"""
        self.base_url = "https://tabletki.ua"
        self.session = requests.Session()
        self.delay_range = delay_range
        
        # Налаштування логування
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
        
        # Заголовки для імітації реального браузера
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'uk-UA,uk;q=0.9,en;q=0.8,ru;q=0.7',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Cache-Control': 'max-age=0',
            'sec-fetch-dest': 'document',
            'sec-fetch-mode': 'navigate',
            'sec-fetch-site': 'none'
        })
        
        self.data: List[PharmacyData] = []
    
    def _random_delay(self):
        """Випадкова затримка між запитами"""
        delay = random.uniform(*self.delay_range)
        time.sleep(delay)
    
    def _make_request(self, url: str, params: dict = None) -> Optional[BeautifulSoup]:
        """Виконання HTTP запиту з обробкою помилок"""
        try:
            self.logger.info(f"Запит до: {url}")
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            
            return BeautifulSoup(response.content, 'html.parser')
            
        except requests.RequestException as e:
            self.logger.error(f"Помилка запиту: {e}")
            return None
    
    def search_products_by_api(self, query: str, city: str = "Київ") -> List[Dict]:
        """
        Пошук товарів через API (якщо доступний)
        """
        # Спроба знайти API endpoints
        api_endpoints = [
            f"{self.base_url}/api/search",
            f"{self.base_url}/search/api",
            f"{self.base_url}/api/products/search"
        ]
        
        for endpoint in api_endpoints:
            try:
                params = {
                    'q': query,
                    'query': query,
                    'search': query,
                    'city': city,
                    'location': city
                }
                
                response = self.session.get(endpoint, params=params, timeout=15)
                if response.status_code == 200:
                    try:
                        data = response.json()
                        self.logger.info(f"Знайдено API endpoint: {endpoint}")
                        return self._parse_api_response(data)
                    except json.JSONDecodeError:
                        continue
                        
            except requests.RequestException:
                continue
        
        return []
    
    def _parse_api_response(self, data: dict) -> List[Dict]:
        """Парсинг відповіді API"""
        products = []
        
        # Різні варіанти структури API відповіді
        if isinstance(data, dict):
            # Варіант 1: data.products або data.items
            items = data.get('products', data.get('items', data.get('results', [])))
            
            # Варіант 2: data.data
            if not items and 'data' in data:
                items = data['data']
                if isinstance(items, dict):
                    items = items.get('products', items.get('items', []))
        elif isinstance(data, list):
            items = data
        else:
            return products
        
        for item in items:
            if isinstance(item, dict):
                product = {
                    'product_name': item.get('name', item.get('title', item.get('product_name', ''))),
                    'price': item.get('price', item.get('cost', '')),
                    'availability': item.get('availability', item.get('in_stock', 'В наявності')),
                    'url': item.get('url', item.get('link', ''))
                }
                
                if product['product_name']:
                    products.append(product)
        
        return products
    
    def search_products_html(self, query: str, city: str = "Київ") -> List[Dict]:
        """
        Пошук товарів через HTML парсинг
        """
        self.logger.info(f"HTML пошук товарів: {query} у місті {city}")
        
        # Різні варіанти URL для пошуку
        search_urls = [
            f"{self.base_url}/search?q={quote(query)}",
            f"{self.base_url}/search.php?search={quote(query)}",
            f"{self.base_url}/products/search?query={quote(query)}",
            f"{self.base_url}/?s={quote(query)}"
        ]
        
        for search_url in search_urls:
            soup = self._make_request(search_url)
            if soup:
                products = self._extract_products_from_html(soup)
                if products:
                    return products
                    
        return []
    
    def _extract_products_from_html(self, soup: BeautifulSoup) -> List[Dict]:
        """Витягування товарів з HTML"""
        products = []
        
        # Різні селектори для товарів
        product_selectors = [
            '.product-item',
            '.product',
            '.item',
            '.search-result',
            '.product-card',
            '[class*="product"]',
            '.listing-item'
        ]
        
        for selector in product_selectors:
            elements = soup.select(selector)
            if elements:
                self.logger.info(f"Знайдено {len(elements)} товарів із селектором {selector}")
                
                for element in elements:
                    product = self._extract_single_product(element)
                    if product:
                        products.append(product)
                        
                if products:
                    break
        
        return products
    
    def _extract_single_product(self, element) -> Optional[Dict]:
        """Витягування даних одного товару"""
        try:
            # Назва товару
            name_selectors = [
                '.product-name', '.name', '.title', 'h3', 'h4', 'h2',
                '[class*="name"]', '[class*="title"]'
            ]
            product_name = ""
            for selector in name_selectors:
                name_elem = element.select_one(selector)
                if name_elem:
                    product_name = name_elem.get_text(strip=True)
                    if product_name:
                        break
            
            # Ціна
            price_selectors = [
                '.price', '.cost', '.amount', '[class*="price"]',
                '[class*="cost"]', '.money'
            ]
            price = ""
            for selector in price_selectors:
                price_elem = element.select_one(selector)
                if price_elem:
                    price = price_elem.get_text(strip=True)
                    if price and any(char.isdigit() for char in price):
                        break
            
            # URL товару
            url = ""
            link_elem = element.select_one('a')
            if link_elem and link_elem.get('href'):
                url = urljoin(self.base_url, link_elem['href'])
            
            # Наявність
            availability = "В наявності"
            availability_selectors = ['.availability', '.status', '.in-stock']
            for selector in availability_selectors:
                avail_elem = element.select_one(selector)
                if avail_elem:
                    availability = avail_elem.get_text(strip=True)
                    break
            
            if product_name and (price or url):
                return {
                    'product_name': product_name,
                    'price': price,
                    'availability': availability,
                    'url': url
                }
                
        except Exception as e:
            self.logger.error(f"Помилка витягування товару: {e}")
            
        return None
    
    def get_pharmacies_from_product_page(self, product_url: str) -> List[PharmacyData]:
        """Отримання списку аптек з сторінки товару"""
        pharmacies = []
        
        if not product_url:
            return pharmacies
            
        soup = self._make_request(product_url)
        if not soup:
            return pharmacies
        
        # Пошук таблиці або списку аптек
        pharmacy_selectors = [
            '.pharmacy-list', '.pharmacies', '.stores',
            '.pharmacy-table', 'table', '.pharmacy-item',
            '[class*="pharmacy"]', '[class*="store"]'
        ]
        
        for selector in pharmacy_selectors:
            elements = soup.select(selector)
            if elements:
                for element in elements:
                    pharmacy_data = self._extract_pharmacy_from_element(element, product_url)
                    if pharmacy_data:
                        pharmacies.append(pharmacy_data)
                        
                if pharmacies:
                    break
        
        # Якщо не знайшли аптеки, пробуємо парсити всю сторінку
        if not pharmacies:
            pharmacies = self._extract_pharmacies_from_page(soup, product_url)
        
        return pharmacies
    
    def _extract_pharmacy_from_element(self, element, product_url: str) -> Optional[PharmacyData]:
        """Витягування даних аптеки з HTML елемента"""
        try:
            # Назва аптеки
            name_selectors = [
                '.pharmacy-name', '.name', '.store-name',
                'h3', 'h4', '.title', '[class*="name"]'
            ]
            pharmacy_name = ""
            for selector in name_selectors:
                name_elem = element.select_one(selector)
                if name_elem:
                    pharmacy_name = name_elem.get_text(strip=True)
                    if pharmacy_name:
                        break
            
            # Адреса
            address_selectors = [
                '.address', '.location', '.street',
                '[class*="address"]', '[class*="location"]'
            ]
            address = ""
            for selector in address_selectors:
                addr_elem = element.select_one(selector)
                if addr_elem:
                    address = addr_elem.get_text(strip=True)
                    if address:
                        break
            
            # Ціна
            price_selectors = [
                '.price', '.cost', '.amount',
                '[class*="price"]', '[class*="cost"]'
            ]
            price = ""
            for selector in price_selectors:
                price_elem = element.select_one(selector)
                if price_elem:
                    price = price_elem.get_text(strip=True)
                    if price and any(char.isdigit() for char in price):
                        break
            
            # Телефон
            phone = ""
            phone_selectors = ['.phone', '.tel', '[class*="phone"]']
            for selector in phone_selectors:
                phone_elem = element.select_one(selector)
                if phone_elem:
                    phone = phone_elem.get_text(strip=True)
                    if phone:
                        break
            
            if pharmacy_name and (address or price):
                return PharmacyData(
                    pharmacy_name=pharmacy_name,
                    address=address,
                    product_name="",  # Буде встановлено пізніше
                    price=price,
                    availability="В наявності",
                    url=product_url,
                    phone=phone
                )
                
        except Exception as e:
            self.logger.error(f"Помилка витягування аптеки: {e}")
            
        return None
    
    def _extract_pharmacies_from_page(self, soup: BeautifulSoup, product_url: str) -> List[PharmacyData]:
        """Витягування аптек з усієї сторінки"""
        pharmacies = []
        
        # Пошук текстових патернів, що можуть вказувати на аптеки
        pharmacy_patterns = [
            r'аптека[\s\w]*',
            r'фармація[\s\w]*',
            r'медикаменти[\s\w]*'
        ]
        
        text = soup.get_text()
        
        # Простий пошук за патернами
        for pattern in pharmacy_patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                # Знаходимо контекст навколо збігу
                start = max(0, match.start() - 100)
                end = min(len(text), match.end() + 100)
                context = text[start:end]
                
                # Пробуємо витягти адресу та ціну з контексту
                # Це базова реалізація, може потребувати покращення
                lines = context.split('\n')
                for line in lines:
                    if 'грн' in line or '₴' in line:
                        # Знайшли рядок з ціною
                        pharmacy_data = PharmacyData(
                            pharmacy_name=match.group(),
                            address="",
                            product_name="",
                            price=line.strip(),
                            availability="В наявності",
                            url=product_url
                        )
                        pharmacies.append(pharmacy_data)
                        break
        
        return pharmacies
    
    def search_specific_product(self, product_name: str, city: str = "Київ") -> List[PharmacyData]:
        """Пошук конкретного товару"""
        self.logger.info(f"Пошук товару: {product_name}")
        
        # Спочатку пробуємо API
        products = self.search_products_by_api(product_name, city)
        
        # Якщо API не спрацював, використовуємо HTML
        if not products:
            products = self.search_products_html(product_name, city)
        
        all_pharmacies = []
        
        for product in products[:5]:  # Обмежуємо кількість
            try:
                pharmacies = self.get_pharmacies_from_product_page(product['url'])
                
                for pharmacy in pharmacies:
                    pharmacy.product_name = product['product_name']
                    all_pharmacies.append(pharmacy)
                
                self._random_delay()
                
            except Exception as e:
                self.logger.error(f"Помилка обробки товару: {e}")
                continue
        
        return all_pharmacies
    
    def parse_popular_products(self) -> List[PharmacyData]:
        """Парсинг популярних товарів"""
        self.logger.info("Парсинг популярних товарів")
        
        soup = self._make_request(self.base_url)
        if not soup:
            return []
        
        # Пошук секції популярних товарів
        popular_selectors = [
            '.popular', '.featured', '.bestsellers',
            '[class*="popular"]', '[class*="featured"]'
        ]
        
        all_pharmacies = []
        
        for selector in popular_selectors:
            section = soup.select_one(selector)
            if section:
                products = self._extract_products_from_html(section)
                
                for product in products[:10]:
                    try:
                        pharmacies = self.get_pharmacies_from_product_page(product['url'])
                        
                        for pharmacy in pharmacies:
                            pharmacy.product_name = product['product_name']
                            all_pharmacies.append(pharmacy)
                        
                        self._random_delay()
                        
                    except Exception as e:
                        self.logger.error(f"Помилка обробки популярного товару: {e}")
                        continue
                
                if all_pharmacies:
                    break
        
        return all_pharmacies
    
    def save_to_csv(self, filename: str = "tabletki_simple_data.csv"):
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
        
        self.logger.info(f"Дані збережено у {filename}")
    
    def save_to_json(self, filename: str = "tabletki_simple_data.json"):
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
        
        self.logger.info(f"Дані збережено у {filename}")


def main():
    """Основна функція"""
    parser = SimpleTabletkiParser()
    
    print("Спрощений Табletки.ua Парсер (без Selenium)")
    print("1. Пошук конкретного товару")
    print("2. Парсинг популярних товарів")
    print("3. Вихід")
    
    choice = input("Виберіть опцію (1-3): ")
    
    if choice == "1":
        product_name = input("Введіть назву товару: ")
        city = input("Введіть місто (або Enter для Київ): ") or "Київ"
        
        data = parser.search_specific_product(product_name, city)
        parser.data = data
        
    elif choice == "2":
        data = parser.parse_popular_products()
        parser.data = data
        
    else:
        return
    
    if parser.data:
        print(f"\nЗнайдено {len(parser.data)} записів")
        
        # Збереження
        save_choice = input("\nЗберегти дані? (csv/json/обидва/ні): ").lower()
        
        if save_choice in ['csv', 'обидва']:
            parser.save_to_csv()
        
        if save_choice in ['json', 'обидва']:
            parser.save_to_json()
        
        # Показати результати
        print("\nПерші 5 записів:")
        for i, item in enumerate(parser.data[:5]):
            print(f"{i+1}. {item.pharmacy_name} - {item.product_name} - {item.price}")
    
    else:
        print("Дані не знайдено")


if __name__ == "__main__":
    main()