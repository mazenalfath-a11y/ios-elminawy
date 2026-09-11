import os

path = r'e:\Projects_code\Flutter\application\lib\screens\appearing_screens\course_details_page.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = {
    'ط§ط´طھط±ظƒ ط§ظ„ط¢ظ†': 'اشترك الآن',
    'ط¬.ظ…': 'ج.م',
    'ط§ظ„ط³ط¹ط± ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ': 'السعر الإجمالي'
}

for old, new in replacements.items():
    content = content.replace(old, new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
