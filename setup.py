#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Скрипт для встановлення та налаштування парсера tabletki.ua
"""

import subprocess
import sys
import os
import platform
from pathlib import Path


def run_command(command, description=""):
    """Виконання команди з перевіркою помилок"""
    print(f"{'='*50}")
    if description:
        print(f"📦 {description}")
    print(f"Виконуємо: {command}")
    print(f"{'='*50}")
    
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        if result.stdout:
            print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Помилка: {e}")
        if e.stderr:
            print(f"Деталі помилки: {e.stderr}")
        return False


def check_python_version():
    """Перевірка версії Python"""
    print("🐍 Перевірка версії Python...")
    
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 7):
        print(f"❌ Потрібен Python 3.7+, знайдено {version.major}.{version.minor}")
        return False
    
    print(f"✅ Python {version.major}.{version.minor}.{version.micro} - OK")
    return True


def install_requirements():
    """Встановлення залежностей"""
    print("\n📦 Встановлення залежностей...")
    
    requirements_file = Path("requirements.txt")
    if not requirements_file.exists():
        print("❌ Файл requirements.txt не знайдено")
        return False
    
    return run_command(
        f"{sys.executable} -m pip install -r requirements.txt",
        "Встановлення Python пакетів"
    )


def install_chromedriver():
    """Встановлення ChromeDriver для Selenium"""
    print("\n🌐 Встановлення ChromeDriver...")
    
    system = platform.system().lower()
    
    if system == "linux":
        # Ubuntu/Debian
        commands = [
            "sudo apt-get update",
            "sudo apt-get install -y chromium-browser chromium-chromedriver"
        ]
        
        for cmd in commands:
            if not run_command(cmd, f"Встановлення ChromeDriver на Linux"):
                return False
                
    elif system == "darwin":  # macOS
        if not run_command("brew --version", "Перевірка Homebrew"):
            print("❌ Homebrew не встановлено. Встановіть його з https://brew.sh/")
            return False
        
        return run_command("brew install chromedriver", "Встановлення ChromeDriver на macOS")
        
    elif system == "windows":
        print("⚠️  Для Windows завантажте ChromeDriver вручну:")
        print("   1. Йдіть на https://chromedriver.chromium.org/")
        print("   2. Завантажте версію для вашої версії Chrome")
        print("   3. Розпакуйте chromedriver.exe до папки в PATH")
        return True
    
    return True


def test_installation():
    """Тестування встановлення"""
    print("\n🧪 Тестування встановлення...")
    
    # Тест імпорту основних модулів
    test_modules = [
        ("requests", "HTTP клієнт"),
        ("bs4", "BeautifulSoup"),
        ("selenium", "Selenium WebDriver (опціонально)")
    ]
    
    success = True
    
    for module, description in test_modules:
        try:
            __import__(module)
            print(f"✅ {description} - OK")
        except ImportError:
            if module == "selenium":
                print(f"⚠️  {description} - не встановлено (можна використовувати спрощений парсер)")
            else:
                print(f"❌ {description} - не встановлено")
                success = False
    
    # Тест простого парсера
    print("\n🔧 Тестування спрощеного парсера...")
    try:
        from tabletki_simple_parser import SimpleTabletkiParser
        parser = SimpleTabletkiParser()
        print("✅ Спрощений парсер - OK")
    except Exception as e:
        print(f"❌ Спрощений парсер - помилка: {e}")
        success = False
    
    # Тест Selenium парсера
    print("\n🔧 Тестування Selenium парсера...")
    try:
        from tabletki_parser import TabletkiParser
        print("✅ Selenium парсер - OK")
    except ImportError as e:
        print(f"⚠️  Selenium парсер - не доступний: {e}")
    except Exception as e:
        print(f"❌ Selenium парсер - помилка: {e}")
    
    return success


def create_sample_files():
    """Створення прикладів файлів"""
    print("\n📄 Створення прикладів...")
    
    # .env файл
    env_content = """# Конфігурація парсера tabletki.ua
DELAY_MIN=1
DELAY_MAX=3
BASE_URL=https://tabletki.ua
HEADLESS=true
LOG_LEVEL=INFO
"""
    
    env_file = Path(".env.example")
    if not env_file.exists():
        with open(env_file, 'w', encoding='utf-8') as f:
            f.write(env_content)
        print("✅ Створено .env.example")
    
    # Тестовий скрипт
    test_content = """#!/usr/bin/env python3
# Простий тест парсера
from tabletki_simple_parser import SimpleTabletkiParser

def quick_test():
    parser = SimpleTabletkiParser()
    print("Тестування парсера...")
    # Тут можна додати базовий тест
    print("Тест завершено!")

if __name__ == "__main__":
    quick_test()
"""
    
    test_file = Path("quick_test.py")
    if not test_file.exists():
        with open(test_file, 'w', encoding='utf-8') as f:
            f.write(test_content)
        print("✅ Створено quick_test.py")


def main():
    """Головна функція установки"""
    print("🏥 Установка парсера tabletki.ua")
    print("=" * 60)
    
    # Перевірка версії Python
    if not check_python_version():
        sys.exit(1)
    
    # Встановлення Python залежностей
    if not install_requirements():
        print("\n❌ Не вдалося встановити залежності")
        choice = input("Продовжити без деяких залежностей? (y/n): ")
        if choice.lower() != 'y':
            sys.exit(1)
    
    # Встановлення ChromeDriver
    print("\n" + "="*60)
    selenium_choice = input("Встановити ChromeDriver для Selenium? (y/n): ")
    if selenium_choice.lower() == 'y':
        install_chromedriver()
    else:
        print("⚠️  Selenium функціонал буде недоступний")
    
    # Тестування
    print("\n" + "="*60)
    if test_installation():
        print("\n✅ Установка завершена успішно!")
    else:
        print("\n⚠️  Установка завершена з помилками")
    
    # Створення прикладів
    create_sample_files()
    
    print("\n" + "="*60)
    print("🎉 Готово до використання!")
    print("\nНаступні кроки:")
    print("1. Запустіть: python example_usage.py")
    print("2. Або: python tabletki_simple_parser.py")
    print("3. Прочитайте README.md для детальної інформації")
    
    # Швидкий запуск
    print("\n" + "="*60)
    quick_start = input("Запустити приклад зараз? (y/n): ")
    if quick_start.lower() == 'y':
        try:
            import example_usage
            example_usage.example_1_search_specific_medicine()
        except Exception as e:
            print(f"Помилка запуску прикладу: {e}")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Установка перервана користувачем")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Неочікувана помилка: {e}")
        sys.exit(1)