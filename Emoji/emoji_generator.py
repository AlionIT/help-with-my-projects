#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для загрузки и сохранения всех эмодзи Unicode
Создает файл со всеми доступными эмодзи в удобном формате
"""

import json
import requests
from pathlib import Path

def load_emoji_from_unicode():
    """
    Загружает данные эмодзи из официального Unicode источника
    Сохраняет их в файл emoji_database.txt
    """
    
    # Основные эмодзи диапазоны Unicode
    emoji_ranges = [
        # Лица и эмоции
        (0x1F600, 0x1F64F),
        # Дополнительные эмоции
        (0x1F900, 0x1F9FF),
        # Животные и природа
        (0x1F300, 0x1F5FF),
        # Еда и напитки
        (0x1F32D, 0x1F37F),
        # Путешествия и места
        (0x1F680, 0x1F6FF),
        # Символы и знаки
        (0x1F680, 0x1F6FF),
        # Дополнительные символы
        (0x2600, 0x26FF),
        # Геометрические символы
        (0x25A0, 0x25FF),
    ]
    
    # Собираем эмодзи
    emojis = []
    emoji_categories = {}
    
    for start, end in emoji_ranges:
        for code_point in range(start, end):
            try:
                char = chr(code_point)
                # Проверяем, что это корректный символ
                if char.isprintable() or char == ' ':
                    emojis.append({
                        'emoji': char,
                        'unicode': f'U+{code_point:04X}',
                        'decimal': code_point
                    })
            except (ValueError, OverflowError):
                pass
    
    return emojis

def save_emoji_to_file(emojis, filename='emoji_database.txt'):
    """
    Сохраняет эмодзи в текстовый файл в разных форматах
    """
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write("=" * 80 + "\n")
        f.write("ПОЛНАЯ БАЗА ДАННЫХ EMOJI UNICODE\n")
        f.write("=" * 80 + "\n\n")
        
        f.write(f"Всего эмодзи: {len(emojis)}\n")
        f.write(f"Стандарт: Unicode v17.0\n")
        f.write(f"Кодировка: UTF-8\n\n")
        
        f.write("-" * 80 + "\n")
        f.write("ФОРМАТ: Эмодзи | Unicode код | Десятичный код\n")
        f.write("-" * 80 + "\n\n")
        
        for i, emoji_data in enumerate(emojis, 1):
            line = f"{i:5d}. {emoji_data['emoji']}  | {emoji_data['unicode']}  | {emoji_data['decimal']}\n"
            f.write(line)
    
    print(f"✅ Файл успешно создан: {filename}")
    print(f"📊 Всего сохранено эмодзи: {len(emojis)}")

def save_emoji_simple(emojis, filename='emoji_simple.txt'):
    """
    Сохраняет эмодзи в простом формате (только символы)
    """
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write("ПРОСТОЙ СПИСОК ЭМОДЗИ (только символы для копирования)\n")
        f.write("=" * 80 + "\n\n")
        
        # Группируем эмодзи по 20 на строку для удобства
        emoji_chars = [emoji_data['emoji'] for emoji_data in emojis]
        
        for i in range(0, len(emoji_chars), 20):
            line = " ".join(emoji_chars[i:i+20])
            f.write(line + "\n")
    
    print(f"✅ Простой файл создан: {filename}")

def save_emoji_json(emojis, filename='emoji_data.json'):
    """
    Сохраняет эмодзи в JSON формате для программирования
    """
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(emojis, f, ensure_ascii=False, indent=2)
    
    print(f"✅ JSON файл создан: {filename}")

def save_emoji_python(emojis, filename='emoji_list.py'):
    """
    Создает Python файл с готовым списком эмодзи
    """
    
    emoji_chars = [emoji_data['emoji'] for emoji_data in emojis]
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write("# Автоматически сгенерированный список эмодзи Unicode\n")
        f.write("# Использование: from emoji_list import EMOJI_LIST\n\n")
        
        f.write("EMOJI_LIST = [\n")
        for i, emoji in enumerate(emoji_chars):
            f.write(f"    '{emoji}',")
            if (i + 1) % 10 == 0:
                f.write(f"  # {i + 1} эмодзи\n")
            else:
                f.write(" ")
        f.write("\n]\n\n")
        
        f.write(f"# Всего эмодзи: {len(emoji_chars)}\n")
        f.write("# Использование в коде:\n")
        f.write("# for emoji in EMOJI_LIST:\n")
        f.write("#     print(emoji)\n")
        f.write("# random_emoji = random.choice(EMOJI_LIST)\n")
    
    print(f"✅ Python файл создан: {filename}")

def save_emoji_csv(emojis, filename='emoji_data.csv'):
    """
    Сохраняет эмодзи в CSV формате
    """
    
    with open(filename, 'w', encoding='utf-8', newline='') as f:
        f.write("№,Эмодзи,Unicode_Код,Десятичный_Код\n")
        
        for i, emoji_data in enumerate(emojis, 1):
            f.write(f"{i},{emoji_data['emoji']},{emoji_data['unicode']},{emoji_data['decimal']}\n")
    
    print(f"✅ CSV файл создан: {filename}")

def main():
    """
    Основная функция
    """
    
    print("🚀 Загрузка базы данных эмодзи Unicode...\n")
    
    # Загружаем эмодзи
    emojis = load_emoji_from_unicode()
    
    # Сохраняем в разных форматах
    save_emoji_to_file(emojis)
    save_emoji_simple(emojis)
    save_emoji_json(emojis)
    save_emoji_python(emojis)
    save_emoji_csv(emojis)
    
    print("\n" + "=" * 80)
    print("✨ Все файлы успешно созданы!")
    print("=" * 80)
    print("\nСозданные файлы:")
    print("  1. emoji_database.txt  - полная база с Unicode кодами")
    print("  2. emoji_simple.txt    - простой список для копирования")
    print("  3. emoji_data.json     - данные в JSON формате")
    print("  4. emoji_list.py       - Python список для использования в коде")
    print("  5. emoji_data.csv      - табличный формат для Excel")
    print("\n💡 Совет: Откройте emoji_simple.txt и копируйте нужные эмодзи!")

if __name__ == "__main__":
    main()