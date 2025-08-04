#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Парсер сайту tabletki.ua
Збір даних за основними параметрами: аптека, адреса, товар, ціна товару
"""

import requests
import json
import csv
import time
import logging
from bs4 import BeautifulSoup
from typing import List, Dict, Optional
from dataclasses import dataclass
from urllib.parse import urljoin, urlparse
import random
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import TimeoutException, NoSuchElementException


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


class TabletkiParser:
    """Основний клас для парсингу сайту tabletki.ua"""
    
    def __init__(self, headless: bool = True, delay_range: tuple = (1, 3)):
        """
        Ініціалізація парсера
        
        Args:
            headless: Запускати браузер у фоновому режимі
            delay_range: Діапазон затримок між запитами (хвилини)
        """
        self.base_url = "https://tabletki.ua"
        self.session = requests.Session()
        self.delay_range = delay_range
        self.headless = headless
        
        # Налаштування логування
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
        
        # Заголовки для імітації реального браузера
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'uk-UA,uk;q=0.9,en;q=0.8',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1'
        })
        
        self.data: List[PharmacyData] = []
    
    def _setup_driver(self) -> webdriver.Chrome:
        """Налаштування Selenium WebDriver"""
        chrome_options = Options()
        if self.headless:
            chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--window-size=1920,1080")
        chrome_options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        
        return webdriver.Chrome(options=chrome_options)
    
    def _random_delay(self):
        """Випадкова затримка між запитами"""
        delay = random.uniform(*self.delay_range)
        time.sleep(delay)
    
    def search_products(self, query: str, city: str = "Київ") -> List[Dict]:
        """
        Пошук товарів на сайті
        
        Args:
            query: Пошуковий запит
            city: Місто для пошуку
            
        Returns:
            Список знайдених товарів
        """
        self.logger.info(f"Пошук товарів: {query} у місті {city}")
        
        driver = self._setup_driver()
        products = []
        
        try:
            # Перехід на головну сторінку
            driver.get(self.base_url)
            self._random_delay()
            
            # Вибір міста (якщо є такий функціонал)
            try:
                city_selector = WebDriverWait(driver, 10).until(
                    EC.element_to_be_clickable((By.XPATH, f"//button[contains(text(), '{city}')]"))
                )
                city_selector.click()
                self._random_delay()
            except TimeoutException:
                self.logger.info("Селектор міста не знайдено, використовуємо за замовчуванням")
            
            # Пошук товару
            search_box = WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.NAME, "search"))
            )
            search_box.clear()
            search_box.send_keys(query)
            
            # Натискання кнопки пошуку
            search_button = driver.find_element(By.XPATH, "//button[@type='submit']")
            search_button.click()
            
            # Очікування результатів
            WebDriverWait(driver, 15).until(
                EC.presence_of_element_located((By.CLASS_NAME, "product-item"))
            )
            
            # Парсинг результатів
            product_elements = driver.find_elements(By.CLASS_NAME, "product-item")
            
            for element in product_elements:
                try:
                    product_data = self._extract_product_data(element, driver)
                    if product_data:
                        products.append(product_data)
                except Exception as e:
                    self.logger.error(f"Помилка при обробці товару: {e}")
                    continue
                    
        except Exception as e:
            self.logger.error(f"Помилка при пошуку товарів: {e}")
        finally:
            driver.quit()
            
        return products
    
    def _extract_product_data(self, element, driver) -> Optional[Dict]:
        """Витягування даних про товар"""
        try:
            # Назва товару
            product_name = element.find_element(By.CLASS_NAME, "product-name").text.strip()
            
            # Ціна
            price_element = element.find_element(By.CLASS_NAME, "price")
            price = price_element.text.strip()
            
            # Наявність
            availability = "В наявності"
            try:
                availability_element = element.find_element(By.CLASS_NAME, "availability")
                availability = availability_element.text.strip()
            except NoSuchElementException:
                pass
            
            # Посилання на сторінку товару
            product_link = element.find_element(By.TAG_NAME, "a").get_attribute("href")
            
            return {
                'product_name': product_name,
                'price': price,
                'availability': availability,
                'url': product_link
            }
            
        except Exception as e:
            self.logger.error(f"Помилка при витягуванні даних товару: {e}")
            return None
    
    def get_pharmacy_details(self, product_url: str) -> List[PharmacyData]:
        """
        Отримання детальної інформації про аптеки для конкретного товару
        
        Args:
            product_url: URL сторінки товару
            
        Returns:
            Список аптек з цінами
        """
        pharmacies = []
        driver = self._setup_driver()
        
        try:
            driver.get(product_url)
            self._random_delay()
            
            # Пошук кнопки "Де купити" або "Аптеки"
            try:
                pharmacy_button = WebDriverWait(driver, 10).until(
                    EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Аптеки')] | //a[contains(text(), 'Де купити')]"))
                )
                pharmacy_button.click()
                self._random_delay()
            except TimeoutException:
                self.logger.info("Кнопка аптек не знайдена")
            
            # Парсинг списку аптек
            pharmacy_elements = driver.find_elements(By.CLASS_NAME, "pharmacy-item")
            
            if not pharmacy_elements:
                # Альтернативні селектори
                pharmacy_elements = driver.find_elements(By.XPATH, "//div[contains(@class, 'pharmacy')] | //tr[contains(@class, 'pharmacy')]")
            
            for element in pharmacy_elements:
                pharmacy_data = self._extract_pharmacy_data(element, product_url)
                if pharmacy_data:
                    pharmacies.append(pharmacy_data)
                    
        except Exception as e:
            self.logger.error(f"Помилка при отриманні даних аптек: {e}")
        finally:
            driver.quit()
            
        return pharmacies
    
    def _extract_pharmacy_data(self, element, product_url: str) -> Optional[PharmacyData]:
        """Витягування даних про аптеку"""
        try:
            # Назва аптеки
            pharmacy_name = ""
            name_selectors = [".pharmacy-name", ".name", "h3", "h4", ".title"]
            for selector in name_selectors:
                try:
                    pharmacy_name = element.find_element(By.CSS_SELECTOR, selector).text.strip()
                    if pharmacy_name:
                        break
                except NoSuchElementException:
                    continue
            
            # Адреса
            address = ""
            address_selectors = [".address", ".pharmacy-address", ".location"]
            for selector in address_selectors:
                try:
                    address = element.find_element(By.CSS_SELECTOR, selector).text.strip()
                    if address:
                        break
                except NoSuchElementException:
                    continue
            
            # Ціна
            price = ""
            price_selectors = [".price", ".cost", ".pharmacy-price"]
            for selector in price_selectors:
                try:
                    price = element.find_element(By.CSS_SELECTOR, selector).text.strip()
                    if price:
                        break
                except NoSuchElementException:
                    continue
            
            # Наявність
            availability = "В наявності"
            try:
                availability_element = element.find_element(By.CSS_SELECTOR, ".availability, .status")
                availability = availability_element.text.strip()
            except NoSuchElementException:
                pass
            
            # Телефон
            phone = ""
            try:
                phone_element = element.find_element(By.CSS_SELECTOR, ".phone, .contact")
                phone = phone_element.text.strip()
            except NoSuchElementException:
                pass
            
            if pharmacy_name and (address or price):
                return PharmacyData(
                    pharmacy_name=pharmacy_name,
                    address=address,
                    product_name="",  # Буде заповнено пізніше
                    price=price,
                    availability=availability,
                    url=product_url,
                    phone=phone
                )
                
        except Exception as e:
            self.logger.error(f"Помилка при витягуванні даних аптеки: {e}")
            
        return None
    
    def parse_categories(self, max_categories: int = 5) -> List[PharmacyData]:
        """
        Парсинг товарів по категоріям
        
        Args:
            max_categories: Максимальна кількість категорій для парсингу
            
        Returns:
            Список всіх знайдених даних
        """
        self.logger.info("Починаємо парсинг категорій")
        
        categories = [
            "ліки від головного болю",
            "антибіотики",
            "вітаміни",
            "жарознижуючі",
            "від кашлю",
            "серцево-судинні",
            "діабет",
            "алергія"
        ]
        
        all_data = []
        
        for i, category in enumerate(categories[:max_categories]):
            self.logger.info(f"Парсинг категорії {i+1}/{max_categories}: {category}")
            
            try:
                products = self.search_products(category)
                
                for product in products[:10]:  # Обмежуємо кількість товарів на категорію
                    try:
                        pharmacies = self.get_pharmacy_details(product['url'])
                        
                        for pharmacy in pharmacies:
                            pharmacy.product_name = product['product_name']
                            all_data.append(pharmacy)
                            
                        self._random_delay()
                        
                    except Exception as e:
                        self.logger.error(f"Помилка при обробці товару {product.get('product_name', '')}: {e}")
                        continue
                        
            except Exception as e:
                self.logger.error(f"Помилка при парсингу категорії {category}: {e}")
                continue
        
        self.data.extend(all_data)
        return all_data
    
    def search_specific_product(self, product_name: str, city: str = "Київ") -> List[PharmacyData]:
        """
        Пошук конкретного товару
        
        Args:
            product_name: Назва товару
            city: Місто
            
        Returns:
            Список аптек з товаром
        """
        self.logger.info(f"Пошук товару: {product_name}")
        
        products = self.search_products(product_name, city)
        all_pharmacies = []
        
        for product in products[:5]:  # Обмежуємо результат
            try:
                pharmacies = self.get_pharmacy_details(product['url'])
                
                for pharmacy in pharmacies:
                    pharmacy.product_name = product['product_name']
                    all_pharmacies.append(pharmacy)
                    
                self._random_delay()
                
            except Exception as e:
                self.logger.error(f"Помилка при обробці товару: {e}")
                continue
        
        return all_pharmacies
    
    def save_to_csv(self, filename: str = "tabletki_data.csv"):
        """Збереження даних у CSV файл"""
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
    
    def save_to_json(self, filename: str = "tabletki_data.json"):
        """Збереження даних у JSON файл"""
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
        """Отримання статистики зібраних даних"""
        if not self.data:
            return {}
        
        pharmacies = set(item.pharmacy_name for item in self.data)
        products = set(item.product_name for item in self.data)
        
        return {
            'total_records': len(self.data),
            'unique_pharmacies': len(pharmacies),
            'unique_products': len(products),
            'pharmacies_list': list(pharmacies),
            'products_list': list(products)
        }


def main():
    """Основна функція"""
    parser = TabletkiParser(headless=True)
    
    print("Табletки.ua Парсер")
    print("1. Пошук конкретного товару")
    print("2. Парсинг по категоріям")
    print("3. Вихід")
    
    choice = input("Виберіть опцію (1-3): ")
    
    if choice == "1":
        product_name = input("Введіть назву товару: ")
        city = input("Введіть місто (або натисніть Enter для Київ): ") or "Київ"
        
        data = parser.search_specific_product(product_name, city)
        parser.data = data
        
    elif choice == "2":
        max_categories = int(input("Кількість категорій для парсингу (1-8): ") or "3")
        data = parser.parse_categories(max_categories)
        
    else:
        return
    
    if parser.data:
        print(f"\nЗнайдено {len(parser.data)} записів")
        
        # Статистика
        stats = parser.get_statistics()
        print(f"Унікальних аптек: {stats['unique_pharmacies']}")
        print(f"Унікальних товарів: {stats['unique_products']}")
        
        # Збереження
        save_choice = input("\nЗберегти дані? (csv/json/обидва/ні): ").lower()
        
        if save_choice in ['csv', 'обидва']:
            parser.save_to_csv()
        
        if save_choice in ['json', 'обидва']:
            parser.save_to_json()
        
        # Показати перші 5 записів
        print("\nПерші 5 записів:")
        for i, item in enumerate(parser.data[:5]):
            print(f"{i+1}. {item.pharmacy_name} - {item.product_name} - {item.price}")
    
    else:
        print("Дані не знайдено")


if __name__ == "__main__":
    main()