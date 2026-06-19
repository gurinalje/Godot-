#!/usr/bin/env node
/**
 * 自动化史诗任务和故事创建脚本
 * 用法: node scripts/auto-epics.mjs [layer]
 * 示例: node scripts/auto-epics.mjs foundation
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync } from 'fs';
import { join, basename } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = join(__dirname, '..');

// 配置
const LAYERS = {
  foundation: ['input-system', 'card-database', 'character-attributes'],
  core: ['damage-calculation', 'status-effect-system', 'combo-chain-system', 'environment-system', 'summon-system', 'story-mark-system', 'element-system', 'rule-rewriting-system', 'dialogue-system', 'skill-tree-system', 'audio-system', 'ui-system'],
  feature: ['card-battle-system', 'choice-system', 'world-state-system', 'region-system', 'npc-system', 'quest-tracker', 'deck-building', 'card-upgrade'],
  presentation: ['world-exploration', 'deck-management', 'narrative-system', 'rpg-progression', 'hidden-content-system']
};

// 工具函数
function readYaml(path) {
  if (!existsSync(path)) return null;
  const content = readFileSync(path, 'utf8');
  const entries = [];
  let current = null;
  
  for (const line of content.split('\n')) {
    if (line.startsWith('- name:')) {
      if (current) entries.push(current);
      current = { name: line.replace('- name:', '').trim() };
    } else if (current && line.includes(':')) {
      const [key, ...valueParts] = line.split(':');
      const value = valueParts.join(':').trim();
      if (key.trim() && value) {
        current[key.trim()] = value;
      }
    }
  }
  if (current) entries.push(current);
  
  return entries;
}

function writeYaml(path, data) {
  const lines = data.map(item => {
    const lines = [`- name: ${item.name}`];
    for (const [key, value] of Object.entries(item)) {
      if (key !== 'name') {
        lines.push(`  ${key}: ${value}`);
      }
    }
    return lines.join('\n');
  });
  writeFileSync(path, lines.join('\n') + '\n');
}

function slugify(name) {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

// 创建史诗任务
function createEpic(systemName, layer, gddPath) {
  const epicSlug = slugify(systemName);
  const epicDir = join(ROOT, 'production', 'epics', epicSlug);
  const epicPath = join(epicDir, 'EPIC.md');
  
  if (existsSync(epicPath)) {
    console.log(`⏭️  史诗任务已存在: ${epicPath}`);
    return { path: epicPath, created: false };
  }
  
  mkdirSync(epicDir, { recursive: true });
  
  const content = `# Epic: ${systemName}

> **Layer**: ${layer}
> **GDD**: ${gddPath}
> **Status**: Ready
> **Stories**: Not yet created — run \`/create-stories ${epicSlug}\`

## Overview

This epic implements the ${systemName} system as defined in the GDD.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001 | Godot Engine Selection | LOW |
| ADR-0002 | GDScript Primary Language | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-${epicSlug}-001 | Core implementation | ADR-0001 ✅ |
| TR-${epicSlug}-002 | Integration with dependent systems | ADR-0002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via \`/story-done\`
- All acceptance criteria from the GDD are verified
- All Logic and Integration stories have passing test files in \`tests/\`

## Next Step

Run \`/create-stories ${epicSlug}\` to break this epic into implementable stories.
`;

  writeFileSync(epicPath, content);
  console.log(`✅ 创建史诗任务: ${epicPath}`);
  return { path: epicPath, created: true };
}

// 创建故事
function createStory(epicSlug, storyNumber, title, type, gddPath, trId) {
  const storySlug = slugify(title);
  const storyPath = join(ROOT, 'production', 'epics', epicSlug, `story-${String(storyNumber).padStart(3, '0')}-${storySlug}.md`);
  
  if (existsSync(storyPath)) {
    console.log(`⏭️  故事已存在: ${storyPath}`);
    return { path: storyPath, created: false };
  }
  
  const content = `# Story ${String(storyNumber).padStart(3, '0')}: ${title}

> **Epic**: ${epicSlug}
> **Status**: Ready
> **Layer**: ${type === 'Logic' ? 'Foundation' : type === 'Integration' ? 'Core' : 'Feature'}
> **Type**: ${type}
> **Manifest Version**: ${new Date().toISOString().split('T')[0]}

## Context

**GDD**: \`${gddPath}\`
**Requirement**: \`${trId}\`

**ADR Governing Implementation**: ADR-0001
**ADR Decision Summary**: Use Godot 4.6.3 as the game engine

**Engine**: Godot 4.6.3 | **Risk**: LOW
**Engine Notes**: Standard Godot patterns apply

**Control Manifest Rules (this layer)**:
- Required: Follow Godot naming conventions
- Forbidden: No hardcoded values
- Guardrail: 60fps target, 16.6ms frame budget

---

## Acceptance Criteria

*From GDD \`${gddPath}\`, scoped to this story:*

- [ ] [Criterion 1 — implement core functionality]
- [ ] [Criterion 2 — handle edge cases]
- [ ] [Performance criterion — within budget]

---

## Implementation Notes

*Derived from ADR-0001 Implementation Guidelines:*

1. Follow Godot 4.6.3 patterns
2. Use GDScript with static typing
3. Implement proper signal architecture
4. Add doc comments on public APIs

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Other system integrations
- UI implementation
- Performance optimization

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: [criterion text]
  - Given: [precondition]
  - When: [action]
  - Then: [assertion]
  - Edge cases: [boundary values / failure states]

---

## Test Evidence

**Story Type**: ${type}
**Required evidence**:
- Logic: \`game/tests/unit/${epicSlug}/${storySlug}_test.gd\` — must exist and pass
- Integration: \`game/tests/integration/${epicSlug}/${storySlug}_test.gd\` OR playtest doc
- Visual/Feel: \`production/qa/evidence/${storySlug}-evidence.md\` + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: [Story NNN+1, or "None"]
`;

  writeFileSync(storyPath, content);
  console.log(`✅ 创建故事: ${storyPath}`);
  return { path: storyPath, created: true };
}

// 更新系统索引
function updateSystemsIndex(systemName, status) {
  const indexPath = join(ROOT, 'design', 'gdd', 'systems-index.md');
  if (!existsSync(indexPath)) {
    console.log(`⚠️  系统索引不存在: ${indexPath}`);
    return;
  }
  
  let content = readFileSync(indexPath, 'utf8');
  const regex = new RegExp(`(\\| ${systemName} \\|.*?\\| )([^|]+)( \\|)`, 'g');
  const match = content.match(regex);
  
  if (match) {
    content = content.replace(regex, `$1${status}$3`);
    writeFileSync(indexPath, content);
    console.log(`✅ 更新系统索引: ${systemName} → ${status}`);
  }
}

// 更新史诗索引
function updateEpicIndex(epicSlug, systemName, layer, gddPath) {
  const indexPath = join(ROOT, 'production', 'epics', 'index.md');
  let content = '';
  
  if (existsSync(indexPath)) {
    content = readFileSync(indexPath, 'utf8');
  } else {
    content = `# Epics Index\n\nLast Updated: ${new Date().toISOString().split('T')[0]}\nEngine: Godot 4.6.3\n\n| Epic | Layer | System | GDD | Stories | Status |\n|------|-------|--------|-----|---------|--------|\n`;
  }
  
  const row = `| ${epicSlug} | ${layer} | ${systemName} | ${gddPath} | Not yet created | Ready |`;
  
  if (!content.includes(epicSlug)) {
    content += row + '\n';
    writeFileSync(indexPath, content);
    console.log(`✅ 更新史诗索引: ${epicSlug}`);
  }
}

// 主函数
function main() {
  const args = process.argv.slice(2);
  const layer = args[0] || 'foundation';
  
  if (!LAYERS[layer]) {
    console.error(`❌ 未知层: ${layer}`);
    console.log(`可用层: ${Object.keys(LAYERS).join(', ')}`);
    process.exit(1);
  }
  
  console.log(`\n🚀 开始处理 ${layer} 层...\n`);
  
  const systems = LAYERS[layer];
  let createdEpics = 0;
  let createdStories = 0;
  
  for (const systemName of systems) {
    const epicSlug = slugify(systemName);
    const gddPath = `game/design/gdd/${epicSlug}.md`;
    
    // 检查GDD是否存在
    if (!existsSync(join(ROOT, gddPath))) {
      console.log(`⚠️  GDD不存在，跳过: ${gddPath}`);
      continue;
    }
    
    // 创建史诗任务
    const epic = createEpic(systemName, layer, gddPath);
    if (epic.created) createdEpics++;
    
    // 更新系统索引
    updateSystemsIndex(systemName, 'Epic Created');
    
    // 更新史诗索引
    updateEpicIndex(epicSlug, systemName, layer, gddPath);
    
    // 创建故事（每个史诗3个故事）
    const storyTypes = ['Logic', 'Integration', 'Visual/Feel'];
    const storyTitles = [
      `Core ${systemName} Implementation`,
      `${systemName} System Integration`,
      `${systemName} Visual Feedback`
    ];
    
    for (let i = 0; i < 3; i++) {
      const story = createStory(
        epicSlug,
        i + 1,
        storyTitles[i],
        storyTypes[i],
        gddPath,
        `TR-${epicSlug}-${String(i + 1).padStart(3, '0')}`
      );
      if (story.created) createdStories++;
    }
  }
  
  console.log(`\n✨ ${layer} 层处理完成!`);
  console.log(`📊 统计:`);
  console.log(`   - 创建史诗任务: ${createdEpics}`);
  console.log(`   - 创建故事: ${createdStories}`);
  console.log(`\n📋 下一步:`);
  console.log(`   1. 运行 /story-readiness 检查故事就绪状态`);
  console.log(`   2. 运行 /dev-story 开始实现故事`);
  console.log(`   3. 运行 /code-review 审查代码`);
  console.log(`   4. 运行 /story-done 完成故事`);
}

main();
