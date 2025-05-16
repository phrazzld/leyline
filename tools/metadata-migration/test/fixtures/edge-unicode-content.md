______________________________________________________________________

id: unicode-test description: Testing unicode content: 你好世界 🌍 emoji: 🚀 special: αβγδε ñ é ü ß last_modified: '2025-01-15'

______________________________________________________________________

# Tenet: Unicode and Special Characters

This document tests the handling of Unicode characters and emojis in both metadata
and content. The parser should correctly handle:

## Unicode Examples

- Chinese: 你好世界 (Hello World)
- Japanese: こんにちは
- Arabic: مرحبا بالعالم
- Emojis: 🚀 🌍 💻 📝
- Mathematical: ∑ ∏ ∫ ∂
- Greek: αβγδε
- Accented: àáäâ èéëê ìíïî òóöô ùúüû ñ
- Special: ™ © ® ¥ € £

## Purpose

Ensures the migration tool properly handles UTF-8 encoded content and preserves
all special characters correctly during the metadata transformation.
