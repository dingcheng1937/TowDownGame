#!/usr/bin/env python3
import re
import os

demo_files = [
    'demo/AttachmentDemo.tscn',
    'demo/EquipDemo.tscn',
    'demo/ItemDemo.tscn',
    'demo/MonsterDemo.tscn',
    'demo/UICrosshairDemo.tscn',
    'demo/UIHitLabelDemo.tscn',
    'demo/UIInventoryDemo.tscn',
    'demo/UIWeaponListDemo.tscn',
    'demo/WeaponDemo.tscn'
]

for filepath in demo_files:
    if not os.path.exists(filepath):
        print(f"跳过不存在的文件: {filepath}")
        continue

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 替换InfoLabel的parent和位置
    # 从 parent="." 改为 parent="PlayerRoot/Anchor/Camera2D"
    # 调整offset使其相对于相机左上角

    # 匹配InfoLabel节点
    pattern = r'\[node name="InfoLabel" type="Label" parent="\."\]'
    replacement = '[node name="InfoLabel" type="Label" parent="PlayerRoot/Anchor/Camera2D"]'
    content = re.sub(pattern, replacement, content)

    # 调整offset位置 (相机中心在屏幕中心，左上角需要负偏移)
    # 假设屏幕宽度800，高度600，相机中心(400,300)
    # InfoLabel在左上角(10,10)，相对于相机中心应该是(-390,-290)
    content = re.sub(
        r'(offset_left = )10\.0',
        r'\1-390.0',
        content
    )
    content = re.sub(
        r'(offset_top = )10\.0',
        r'\1-290.0',
        content
    )
    content = re.sub(
        r'(offset_right = )(\d+)\.0',
        r'\1-440.0',  # 10 + 文本宽度
        content
    )
    content = re.sub(
        r'(offset_bottom = )(\d+)\.0',
        r'\1-180.0',  # 10 + 文本高度
        content
    )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"已更新: {filepath}")

print("\n完成！所有InfoLabel已移到Camera2D下作为HUD显示")
