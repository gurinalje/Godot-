## 区域配置资源
## 定义单个区域的所有属性，用于数据驱动的区域管理系统
class_name AreaConfig
extends Resource

## 区域唯一标识符
@export var area_id: String = ""

## 区域显示名称
@export var display_name: String = ""

## 区域描述文本
@export var description: String = ""

## 区域背景颜色
@export var background_color: Color = Color.WHITE

## 区域内的敌人列表
@export var enemies: Array[String] = []

## 区域内的NPC列表
@export var npcs: Array[String] = []

## 可连接的区域列表
@export var connections: Array[String] = []

## 解锁所需等级
@export var unlock_level: int = 1
