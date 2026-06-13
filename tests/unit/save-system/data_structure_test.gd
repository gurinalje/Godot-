# data_structure_test.gd
# PROTOTYPE - NOT FOR PRODUCTION
# Story: 存档数据结构
# Date: 2026-06-03

extends GutTest

## 存档数据结构测试
## 测试SaveData类的序列化和反序列化功能

var save_data: SaveData

func before_each():
	save_data = SaveData.new()

## AC-1: 存档数据包含version字段
func test_serialize_contains_version():
	var data = save_data.serialize()
	assert_true(data.has("version"), "存档数据应包含version字段")
	assert_is(data["version"], TYPE_STRING, "version字段应为字符串类型")

## AC-2: 存档数据包含timestamp字段
func test_serialize_contains_timestamp():
	save_data.timestamp = "2026-06-03T12:00:00"
	var data = save_data.serialize()
	assert_true(data.has("timestamp"), "存档数据应包含timestamp字段")
	assert_is(data["timestamp"], TYPE_STRING, "timestamp字段应为字符串类型")

## AC-3: 存档数据包含player字段
func test_serialize_contains_player():
	var data = save_data.serialize()
	assert_true(data.has("player"), "存档数据应包含player字段")
	assert_is(data["player"], TYPE_DICTIONARY, "player字段应为Dictionary类型")
	
	var player = data["player"]
	assert_true(player.has("level"), "player应包含level字段")
	assert_true(player.has("experience"), "player应包含experience字段")
	assert_true(player.has("attributes"), "player应包含attributes字段")
	assert_true(player.has("gold"), "player应包含gold字段")

## AC-4: 存档数据包含cards字段
func test_serialize_contains_cards():
	var data = save_data.serialize()
	assert_true(data.has("cards"), "存档数据应包含cards字段")
	assert_is(data["cards"], TYPE_DICTIONARY, "cards字段应为Dictionary类型")
	
	var cards = data["cards"]
	assert_true(cards.has("collection"), "cards应包含collection字段")
	assert_true(cards.has("deck"), "cards应包含deck字段")
	assert_true(cards.has("levels"), "cards应包含levels字段")

## AC-5: 存档数据包含worlds字段
func test_serialize_contains_worlds():
	var data = save_data.serialize()
	assert_true(data.has("worlds"), "存档数据应包含worlds字段")
	assert_is(data["worlds"], TYPE_DICTIONARY, "worlds字段应为Dictionary类型")
	
	var worlds = data["worlds"]
	assert_true(worlds.has("forest"), "worlds应包含forest字段")
	assert_true(worlds.has("castle"), "worlds应包含castle字段")
	assert_true(worlds.has("ruins"), "worlds应包含ruins字段")
	assert_true(worlds.has("void"), "worlds应包含void字段")

## AC-6: 存档数据包含stories字段
func test_serialize_contains_stories():
	var data = save_data.serialize()
	assert_true(data.has("stories"), "存档数据应包含stories字段")
	assert_is(data["stories"], TYPE_DICTIONARY, "stories字段应为Dictionary类型")
	
	var stories = data["stories"]
	assert_true(stories.has("main_quest"), "stories应包含main_quest字段")
	assert_true(stories.has("side_quests"), "stories应包含side_quests字段")
	assert_true(stories.has("hidden_stories"), "stories应包含hidden_stories字段")

## AC-7: 存档数据包含marks字段
func test_serialize_contains_marks():
	var data = save_data.serialize()
	assert_true(data.has("marks"), "存档数据应包含marks字段")
	assert_is(data["marks"], TYPE_DICTIONARY, "marks字段应为Dictionary类型")
	
	var marks = data["marks"]
	assert_true(marks.has("good"), "marks应包含good字段")
	assert_true(marks.has("evil"), "marks应包含evil字段")
	assert_true(marks.has("neutral"), "marks应包含neutral字段")

## 测试反序列化
func test_deserialize_from_dictionary():
	var data = {
		"version": "1.0",
		"timestamp": "2026-06-03T12:00:00",
		"player": {
			"level": 10,
			"experience": 1500,
			"attributes": {
				"strength": 25,
				"dexterity": 20,
				"intelligence": 30,
				"constitution": 22,
				"perception": 18,
				"luck": 15
			},
			"gold": 5000
		},
		"cards": {
			"collection": ["card_001", "card_002"],
			"deck": ["card_001"],
			"levels": {"card_001": 3, "card_002": 1}
		},
		"worlds": {
			"forest": {"unlocked": true, "completed": true},
			"castle": {"unlocked": true, "completed": false}
		},
		"stories": {
			"main_quest": {"progress": 5, "choices": ["choice_1", "choice_2"]}
		},
		"marks": {
			"good": 3,
			"evil": 1,
			"neutral": 2
		}
	}
	
	var deserialized = SaveData.deserialize(data)
	assert_eq(deserialized.version, "1.0")
	assert_eq(deserialized.timestamp, "2026-06-03T12:00:00")
	assert_eq(deserialized.get_player_level(), 10)
	assert_eq(deserialized.get_player_experience(), 1500)
	assert_eq(deserialized.get_player_gold(), 5000)
	assert_eq(deserialized.get_card_collection_count(), 2)
	assert_eq(deserialized.get_deck_count(), 1)
	assert_true(deserialized.is_world_unlocked("forest"))
	assert_true(deserialized.is_world_completed("forest"))
	assert_eq(deserialized.get_mark_count("good"), 3)

## 测试验证功能
func test_validate_valid_data():
	save_data.version = "1.0"
	save_data.timestamp = "2026-06-03T12:00:00"
	assert_true(save_data.validate(), "有效数据应通过验证")

func test_validate_empty_version():
	save_data.version = ""
	save_data.timestamp = "2026-06-03T12:00:00"
	assert_false(save_data.validate(), "空版本号应验证失败")

func test_validate_empty_timestamp():
	save_data.version = "1.0"
	save_data.timestamp = ""
	assert_false(save_data.validate(), "空时间戳应验证失败")

## 测试辅助方法
func test_get_player_attribute():
	save_data.player_data["attributes"]["strength"] = 25
	assert_eq(save_data.get_player_attribute("strength"), 25)
	assert_eq(save_data.get_player_attribute("dexterity"), 10)  # 默认值

func test_get_card_level():
	save_data.cards_data["levels"]["card_001"] = 3
	assert_eq(save_data.get_card_level("card_001"), 3)
	assert_eq(save_data.get_card_level("card_999"), 1)  # 默认值

func test_is_world_unlocked():
	save_data.worlds_data["forest"]["unlocked"] = true
	assert_true(save_data.is_world_unlocked("forest"))
	assert_false(save_data.is_world_unlocked("castle"))  # 默认值

func test_get_mark_count():
	save_data.marks_data["good"] = 5
	assert_eq(save_data.get_mark_count("good"), 5)
	assert_eq(save_data.get_mark_count("evil"), 0)  # 默认值
