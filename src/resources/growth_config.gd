## 成长属性配置资源
## 定义单个属性的元数据，用于数据驱动的RPG成长系统
class_name GrowthConfig
extends Resource

## 属性唯一标识符（如 "strength", "dexterity"）
@export var stat_id: String = ""

## 属性显示名称（如 "力量", "敏捷"）
@export var display_name: String = ""

## 属性描述文本
@export var description: String = ""

## 属性图标路径（可选）
@export var icon: Texture2D = null

## 属性初始默认值
@export var default_value: int = 10

## 属性颜色（用于UI显示）
@export var stat_color: Color = Color.WHITE

## 从字典创建GrowthConfig的工厂方法
static func from_dict(stat_id: String, data: Dictionary) -> GrowthConfig:
	var config := GrowthConfig.new()
	config.stat_id = stat_id
	config.display_name = data.get("display_name", stat_id)
	config.description = data.get("description", "")
	config.default_value = data.get("default_value", 10)
	config.stat_color = data.get("stat_color", Color.WHITE)
	return config

## 转换为字典格式（兼容旧系统）
func to_dict() -> Dictionary:
	return {
		"stat_id": stat_id,
		"display_name": display_name,
		"description": description,
		"default_value": default_value,
		"stat_color": stat_color,
	}
