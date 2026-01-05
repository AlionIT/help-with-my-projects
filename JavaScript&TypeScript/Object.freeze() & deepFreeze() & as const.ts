export { }; // Достаточно пустого экспорта - чтобы VsCode воспринимало файл как модуль и не обращало внимание на пересечение с именами внутри проекта где буду открывать этот файл
// символ ❌ в комментариях строки кода означает что данная строка выдает ошибку при нашей (почти максимальной) строгости TypeScript - если такую строку раскоментировать то она должна выдавать ошибку
// { эти блоки если они есть - нужны для экранирования имен переменных внутри блока }

/*
## 🛡️ Стандарты качества(строгости TypeScript) кода в этом файле:
*       Все примеры проверены с максимально возможно для учебных материалов строгими настройками TypeScript.
*       Этот справочник использует конфигурацию TypeScript уровня "Enterprise Strict":
*           *ВКЛЮЧЕНЫ ВСЕ STRICT ПРАВИЛА* (за исключением Группа 3: "noUnusedLocals") в файле tsconfig.ts в разделе
*           "🛡️ 4. БЛОК БЕЗОПАСНОСТИ И ТИПОВ (STRICTNESS): подразделы: 1, 2, 3".
*/


/** =====================================================================================================================
    Сравнение всех методов заморозки состояния объектов JavaScript/TypeScript:
       * Object.freeze()
       * deepFreeze()
       * as const
    ===================================================================================================================== */
/*
┌───────────────────────────┬────────────────┬──────────────────┬────────────────┐
│ Защита                    │ as const       │ Object.freeze()  │ deepFreeze()   │
├───────────────────────────┼────────────────┼──────────────────┼────────────────┤
│ TypeScript (compile-time) │ ✅ Да          │ ❌ Нет*          │ ❌ Нет*        │
│ JavaScript (runtime)      │ ❌ Нет         │ ✅ Shallow       │ ✅ Deep        │
│ Вложенные объекты (types) │ ✅ Readonly    │ ❌ Не меняет     │ ❌ Не меняет   │
│ Вложенные объекты (runtime)│ ❌ Не замораж. │ ❌ Не замораж.   │ ✅ Заморожены  │
│ После компиляции          │ ❌ Исчезает    │ ✅ Работает      │ ✅ Работает    │
└───────────────────────────┴────────────────┴──────────────────┴────────────────┘
* Можно добавить типы вручную: Object.freeze(obj) as Readonly<typeof obj>
*/





/**1️⃣ Object.freeze() — JavaScript встроенный (2009) */
/*
    Когда появился: ES5 (2009)
    Что это: Встроенный метод JavaScript
    Часть стандарта ECMAScript
    Работает в runtime (во время выполнения программы)
    Что делает: */
{
    const obj = {
        name: 'John',
        address: { city: 'Moscow' }
    };

    Object.freeze(obj);

    obj.name = 'Jane';           // ⚠️ TypeScript OK! Runtime Error в strict mode
    obj.address.city = 'SPb';    // ✅ TypeScript OK, Runtime OK (shallow freeze!)

    // Чтобы TypeScript видел заморозку:
    const frozen = Object.freeze(obj) as Readonly<typeof obj>;
    // frozen.name = 'Test';  // ❌ TypeScript Error
}
/*
Ограничения:
   * ⚠️ Shallow(поверхностная) заморозка
   * Замораживает только первый уровень
   * Вложенные объекты остаются изменяемыми
   * Годится для:
       * Простых объектов без вложенности
       * Массивов примитивов
*/





/**2️⃣ deepFreeze() — Пользовательская функция(2010 - е) */
/*
    Когда появился:Паттерн существует с ~2010 - 2012
    Популяризирован в Redux(2015) и функциональном программировании
    НЕ встроен в JavaScript / TypeScript
    Что это: Пользовательская функция - утилита
    Рекурсивно применяет Object.freeze() ко всем вложенным объектам
    Каждый проект реализует свою версию
    Типичная реализация:
*/
{
    // Типизированная версия с generic
    function deepFreeze<T>(obj: T): T {
        // Замораживаем сам объект
        Object.freeze(obj);

        // Рекурсивно замораживаем все свойства
        Object.getOwnPropertyNames(obj).forEach(prop => {
            const value = (obj as any)[prop];
            if (value !== null
                && (typeof value === 'object' || typeof value === 'function')
                && !Object.isFrozen(value)) {
                deepFreeze(value);
            }
        });

        return obj;
    }

    /* Что делает: */
    const obj = {
        name: 'John',
        address: { city: 'Moscow' }
    };

    deepFreeze(obj);

    // obj.name = 'Jane';           // ⚠️ TypeScript OK, Runtime Error
    // obj.address.city = 'SPb';    // ⚠️ TypeScript OK, Runtime Error
}
/*
    Годится для:
       * Сложных вложенных структур
       * Конфигурации
       * Immutable data structures
*/




/**3️⃣ as const — TypeScript фича (2019) */
/*
    Когда появился: TypeScript 3.4(март 2019)
    Что это: Синтаксис TypeScript(не JavaScript!)
    Работает только на этапе компиляции
    Исчезает после компиляции в JavaScript
    Что делает:
    */
{
    const obj = {
        name: 'John',
        age: 30,
        address: { city: 'Moscow' },  // ← Добавили вложенный объект!
        tags: ['dev', 'ts']
    } as const;

    /*
    TypeScript сужает типы до литеральных (рекурсивно для всех уровней):
      • obj.name: 'John'                      (не string!)
      • obj.age: 30                           (не number!)
      • obj.address: { readonly city: 'Moscow' }
      • obj.address.city: 'Moscow'            (не string! readonly!)
      • obj.tags: readonly ['dev', 'ts']
    */

    // obj.name = 'Jane';        // ❌ TypeScript Error
    // obj.address.city = 'SPb'; // ❌ TypeScript Error (вложенные тоже readonly!)
    // obj.tags.push('js');      // ❌ TypeScript Error
}

// После компиляции в JavaScript:
{
    const obj = {
        name: 'John',
        age: 30,
        address: { city: 'Moscow' },
        tags: ['dev', 'ts']
    };
    // as const полностью исчез!

    obj.name = 'Jane';        // ✅ Работает в runtime!
    obj.address.city = 'SPb'; // ✅ Работает в runtime!
    obj.tags.push('js');      // ✅ Работает в runtime!
}
/*
    Ограничения:
        ⚠️ Только проверка типов(compile - time)
        ⚠️ НЕ защищает в runtime
        ⚠️ Исчезает после компиляции

    Годится для:
       * Создания union типов: 'red' | 'green' | 'blue'
       * Константных массивов: readonly['a', 'b', 'c']
       * Type safety во время разработки
*/
