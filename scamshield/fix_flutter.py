import os

def replace_in_file(filepath, replacements):
    if not os.path.exists(filepath):
        print(f"Skipping {filepath}, does not exist.")
        return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old, new in replacements:
        content = content.replace(old, new)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

base_dir = r"d:\ScamShield\scamshield\lib"

# 1. shield_emblem.dart
replace_in_file(os.path.join(base_dir, "widgets", "shield_emblem.dart"), [
    ("ShieldEmblем", "ShieldEmblem"),
    ("""// Public alias (avoids Cyrillic "м" in the internal name)
class ShieldEmblem extends ShieldEmblем {
  const ShieldEmblem({
    super.key,
    super.verdict,
    super.size,
    super.animate,
    super.variant,
  });
}""", "")
])

# 2. app_theme.dart - remove flexibleSpace
replace_in_file(os.path.join(base_dir, "theme", "app_theme.dart"), [
    ("flexibleSpace:", "// flexibleSpace:")
])

print("Fixes applied.")
