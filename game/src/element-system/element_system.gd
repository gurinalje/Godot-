## 元素系统
## 管理元素切换和元素效果
## 元素名称、颜色、克制关系等工具方法统一使用 CardEnums

class_name ElementSystem
extends Node

# 当前选择的元素
var current_element: CardEnums.Element = CardEnums.Element.FIRE

# 元素解锁状态
var unlocked_elements: Array[CardEnums.Element] = [
	CardEnums.Element.FIRE,
	CardEnums.Element.WATER,
	CardEnums.Element.WIND,
	CardEnums.Element.EARTH,
	CardEnums.Element.LIGHTNING
]

# 元素加成
var element_bonuses: Dictionary = {}

# 信号
signal element_changed(new_element: CardEnums.Element)
signal element_unlocked(element: CardEnums.Element)

func _ready() -> void:
	initialize()

func initialize() -> void:
	print("[ElementSystem] Initialized")
	_initialize_bonuses()

## 初始化元素加成
func _initialize_bonuses() -> void:
	for element in CardEnums.Element.values():
		element_bonuses[element] = 1.0

## 切换元素
func switch_element(element: CardEnums.Element) -> bool:
	if not is_element_unlocked(element):
		push_warning("[ElementSystem] Element not unlocked: " + str(element))
		return false
	
	current_element = element
	element_changed.emit(element)
	print("[ElementSystem] Switched to element: ", element)
	return true

## 获取当前元素
func get_current_element() -> CardEnums.Element:
	return current_element

## 检查元素是否解锁
func is_element_unlocked(element: CardEnums.Element) -> bool:
	return element in unlocked_elements

## 解锁元素
func unlock_element(element: CardEnums.Element) -> void:
	if not element in unlocked_elements:
		unlocked_elements.append(element)
		element_unlocked.emit(element)
		print("[ElementSystem] Unlocked element: ", element)

## 获取元素加成
func get_element_bonus(element: CardEnums.Element) -> float:
	return element_bonuses.get(element, 1.0)

## 设置元素加成
func set_element_bonus(element: CardEnums.Element, bonus: float) -> void:
	element_bonuses[element] = bonus

## 获取元素名称
## 委托给 CardEnums.get_element_name() 作为单一数据源
func get_element_name(element: CardEnums.Element) -> String:
	return CardEnums.get_element_name(element)

## 获取元素颜色
## 委托给 CardEnums.get_element_color() 作为单一数据源
func get_element_color(element: CardEnums.Element) -> Color:
	return CardEnums.get_element_color(element)

## 获取克制关系
## 委托给 CardEnums.get_element_modifier() 作为单一数据源
func get_element_advantage(attack: CardEnums.Element, defense: CardEnums.Element) -> float:
	return CardEnums.get_element_modifier(attack, defense)
