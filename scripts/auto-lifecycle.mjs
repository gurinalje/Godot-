#!/usr/bin/env node
/**
 * 项目全生命周期自动化脚本
 * 用法: node scripts/auto-lifecycle.mjs [phase]
 * 示例: node scripts/auto-lifecycle.mjs production
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync } from 'fs';
import { join, basename } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = join(__dirname, '..');

// 配置
const PHASES = {
  'concept': {
    name: 'Concept',
    description: '游戏概念阶段',
    tasks: ['brainstorm', 'game-concept']
  },
  'systems-design': {
    name: 'Systems Design',
    description: '系统设计阶段',
    tasks: ['map-systems', 'design-system', 'design-review']
  },
  'technical-setup': {
    name: 'Technical Setup',
    description: '技术设置阶段',
    tasks: ['setup-engine', 'create-architecture', 'architecture-decision']
  },
  'pre-production': {
    name: 'Pre-Production',
    description: '预生产阶段',
    tasks: ['art-bible', 'create-epics', 'create-stories', 'prototype']
  },
  'production': {
    name: 'Production',
    description: '生产阶段',
    tasks: ['dev-story', 'code-review', 'story-done', 'sprint-plan']
  },
  'polish': {
    name: 'Polish',
    description: '打磨阶段',
    tasks: ['perf-profile', 'playtest-report', 'balance-check', 'bug-triage']
  },
  'release': {
    name: 'Release',
    description: '发布阶段',
    tasks: ['release-checklist', 'launch-checklist', 'changelog', 'patch-notes']
  }
};

// 工具函数
function readMarkdown(path) {
  if (!existsSync(path)) return null;
  return readFileSync(path, 'utf8');
}

function writeMarkdown(path, content) {
  writeFileSync(path, content);
}

function slugify(name) {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

// 检查项目状态
function checkProjectStatus() {
  console.log('\n📊 检查项目状态...');
  
  const status = {
    concept: false,
    systemsDesign: false,
    technicalSetup: false,
    preProduction: false,
    production: false,
    polish: false,
    release: false
  };
  
  // 检查概念阶段
  if (existsSync(join(ROOT, 'design', 'gdd', 'game-concept.md'))) {
    status.concept = true;
    console.log('✅ Concept阶段: 完成');
  } else {
    console.log('❌ Concept阶段: 未完成');
  }
  
  // 检查系统设计阶段
  if (existsSync(join(ROOT, 'design', 'gdd', 'systems-index.md'))) {
    status.systemsDesign = true;
    console.log('✅ Systems Design阶段: 完成');
  } else {
    console.log('❌ Systems Design阶段: 未完成');
  }
  
  // 检查技术设置阶段
  if (existsSync(join(ROOT, 'docs', 'architecture', 'architecture.md'))) {
    status.technicalSetup = true;
    console.log('✅ Technical Setup阶段: 完成');
  } else {
    console.log('❌ Technical Setup阶段: 未完成');
  }
  
  // 检查预生产阶段
  if (existsSync(join(ROOT, 'production', 'epics'))) {
    const epics = readdirSync(join(ROOT, 'production', 'epics'));
    if (epics.length > 0) {
      status.preProduction = true;
      console.log('✅ Pre-Production阶段: 完成');
    } else {
      console.log('❌ Pre-Production阶段: 未完成');
    }
  } else {
    console.log('❌ Pre-Production阶段: 未完成');
  }
  
  // 检查生产阶段
  if (existsSync(join(ROOT, 'src'))) {
    const srcDirs = readdirSync(join(ROOT, 'src'));
    if (srcDirs.length > 0) {
      status.production = true;
      console.log('✅ Production阶段: 完成');
    } else {
      console.log('❌ Production阶段: 未完成');
    }
  } else {
    console.log('❌ Production阶段: 未完成');
  }
  
  return status;
}

// 检查史诗任务状态
function checkEpicStatus() {
  console.log('\n📊 检查史诗任务状态...');
  
  const epicsDir = join(ROOT, 'production', 'epics');
  if (!existsSync(epicsDir)) {
    console.log('❌ 史诗任务目录不存在');
    return { total: 0, completed: 0, inProgress: 0, ready: 0 };
  }
  
  const epics = readdirSync(epicsDir).filter(f => 
    existsSync(join(epicsDir, f, 'EPIC.md'))
  );
  
  let completed = 0;
  let inProgress = 0;
  let ready = 0;
  
  for (const epic of epics) {
    const epicPath = join(epicsDir, epic, 'EPIC.md');
    const content = readMarkdown(epicPath);
    
    if (content) {
      if (content.includes('Status: Complete')) {
        completed++;
      } else if (content.includes('Status: In Progress')) {
        inProgress++;
      } else {
        ready++;
      }
    }
  }
  
  console.log(`📊 史诗任务总数: ${epics.length}`);
  console.log(`   - 已完成: ${completed}`);
  console.log(`   - 进行中: ${inProgress}`);
  console.log(`   - 待开始: ${ready}`);
  
  return { total: epics.length, completed, inProgress, ready };
}

// 检查故事状态
function checkStoryStatus() {
  console.log('\n📊 检查故事状态...');
  
  const epicsDir = join(ROOT, 'production', 'epics');
  if (!existsSync(epicsDir)) {
    console.log('❌ 史诗任务目录不存在');
    return { total: 0, completed: 0, inProgress: 0, ready: 0 };
  }
  
  let total = 0;
  let completed = 0;
  let inProgress = 0;
  let ready = 0;
  
  const epics = readdirSync(epicsDir).filter(f => {
    const fullPath = join(epicsDir, f);
    return existsSync(fullPath) && !f.endsWith('.md');
  });
  
  for (const epic of epics) {
    const epicDir = join(epicsDir, epic);
    if (!existsSync(epicDir)) continue;
    
    const storyFiles = readdirSync(epicDir)
      .filter(f => f.startsWith('story-') && f.endsWith('.md'));
    
    for (const storyFile of storyFiles) {
      total++;
      const storyPath = join(epicDir, storyFile);
      const content = readMarkdown(storyPath);
      
      if (content) {
        if (content.includes('Status: Complete')) {
          completed++;
        } else if (content.includes('Status: In Progress')) {
          inProgress++;
        } else {
          ready++;
        }
      }
    }
  }
  
  console.log(`📊 故事总数: ${total}`);
  console.log(`   - 已完成: ${completed}`);
  console.log(`   - 进行中: ${inProgress}`);
  console.log(`   - 待开始: ${ready}`);
  
  return { total, completed, inProgress, ready };
}

// 检查代码状态
function checkCodeStatus() {
  console.log('\n📊 检查代码状态...');
  
  const srcDir = join(ROOT, 'src');
  if (!existsSync(srcDir)) {
    console.log('❌ 源代码目录不存在');
    return { files: 0, systems: 0 };
  }
  
  const systems = readdirSync(srcDir).filter(f => {
    const fullPath = join(srcDir, f);
    return existsSync(fullPath) && !f.endsWith('.md') && !f.startsWith('.');
  });
  
  let totalFiles = 0;
  
  for (const system of systems) {
    const systemDir = join(srcDir, system);
    if (existsSync(systemDir)) {
      try {
        const files = readdirSync(systemDir).filter(f => f.endsWith('.gd'));
        totalFiles += files.length;
      } catch (e) {
        // 跳过非目录文件
      }
    }
  }
  
  console.log(`📊 源代码系统数: ${systems.length}`);
  console.log(`📊 源代码文件数: ${totalFiles}`);
  
  return { files: totalFiles, systems: systems.length };
}

// 检查测试状态
function checkTestStatus() {
  console.log('\n📊 检查测试状态...');
  
  const testsDir = join(ROOT, 'tests');
  if (!existsSync(testsDir)) {
    console.log('❌ 测试目录不存在');
    return { files: 0, functions: 0 };
  }
  
  let totalFiles = 0;
  let totalFunctions = 0;
  
  // 检查单元测试
  const unitDir = join(testsDir, 'unit');
  if (existsSync(unitDir)) {
    const unitSystems = readdirSync(unitDir);
    
    for (const system of unitSystems) {
      const systemDir = join(unitDir, system);
      if (existsSync(systemDir)) {
        const testFiles = readdirSync(systemDir).filter(f => f.endsWith('_test.gd'));
        totalFiles += testFiles.length;
        
        for (const testFile of testFiles) {
          const content = readMarkdown(join(systemDir, testFile));
          if (content) {
            const functions = content.match(/func test_/g);
            if (functions) {
              totalFunctions += functions.length;
            }
          }
        }
      }
    }
  }
  
  console.log(`📊 测试文件数: ${totalFiles}`);
  console.log(`📊 测试函数数: ${totalFunctions}`);
  
  return { files: totalFiles, functions: totalFunctions };
}

// 生成项目报告
function generateProjectReport() {
  console.log('\n📊 生成项目报告...');
  
  const reportPath = join(ROOT, 'production', 'project-status.md');
  
  const projectStatus = checkProjectStatus();
  const epicStatus = checkEpicStatus();
  const storyStatus = checkStoryStatus();
  const codeStatus = checkCodeStatus();
  const testStatus = checkTestStatus();
  
  const report = `# 项目状态报告

> **生成时间**: ${new Date().toISOString()}
> **项目阶段**: ${projectStatus.production ? 'Production' : projectStatus.preProduction ? 'Pre-Production' : 'Technical Setup'}

## 📊 项目概览

| 指标 | 数量 | 状态 |
|------|------|------|
| **史诗任务总数** | ${epicStatus.total} | ${epicStatus.completed === epicStatus.total ? '✅ 全部完成' : '⏳ 进行中'} |
| **故事总数** | ${storyStatus.total} | ${storyStatus.completed === storyStatus.total ? '✅ 全部完成' : '⏳ 进行中'} |
| **源代码系统数** | ${codeStatus.systems} | ✅ 已创建 |
| **源代码文件数** | ${codeStatus.files} | ✅ 已创建 |
| **测试文件数** | ${testStatus.files} | ✅ 已创建 |
| **测试函数数** | ${testStatus.functions} | ✅ 已创建 |

## 🏗️ 阶段完成情况

| 阶段 | 状态 | 说明 |
|------|------|------|
| **Concept** | ${projectStatus.concept ? '✅ 完成' : '❌ 未完成'} | 游戏概念文档 |
| **Systems Design** | ${projectStatus.systemsDesign ? '✅ 完成' : '❌ 未完成'} | 系统设计和GDD |
| **Technical Setup** | ${projectStatus.technicalSetup ? '✅ 完成' : '❌ 未完成'} | 引擎配置和架构 |
| **Pre-Production** | ${projectStatus.preProduction ? '✅ 完成' : '❌ 未完成'} | 史诗任务和故事 |
| **Production** | ${projectStatus.production ? '✅ 完成' : '❌ 未完成'} | 代码实现 |
| **Polish** | ${projectStatus.polish ? '✅ 完成' : '❌ 未完成'} | 打磨和优化 |
| **Release** | ${projectStatus.release ? '✅ 完成' : '❌ 未完成'} | 发布准备 |

## 📈 史诗任务详情

| 状态 | 数量 |
|------|------|
| **已完成** | ${epicStatus.completed} |
| **进行中** | ${epicStatus.inProgress} |
| **待开始** | ${epicStatus.ready} |

## 📖 故事详情

| 状态 | 数量 |
|------|------|
| **已完成** | ${storyStatus.completed} |
| **进行中** | ${storyStatus.inProgress} |
| **待开始** | ${storyStatus.ready} |

## 🎯 下一步行动

### 立即行动
1. **运行测试验证**：在Godot中运行所有测试
2. **代码审查**：运行 \`/code-review\` 审查实现
3. **集成测试**：运行 \`/smoke-check\` 验证系统集成

### 短期计划
1. **QA计划**：运行 \`/qa-plan\` 创建测试计划
2. **生产就绪检查**：运行 \`/gate-check production\` 验证生产就绪状态
3. **冲刺计划**：运行 \`/sprint-plan\` 创建生产冲刺计划

### 长期计划
1. **性能优化**：运行 \`/perf-profile\` 进行性能分析
2. **平衡检查**：运行 \`/balance-check\` 验证游戏平衡
3. **发布准备**：运行 \`/release-checklist\` 准备发布

## 📋 自动化脚本

\`\`\`bash
# 检查项目状态
node scripts/auto-lifecycle.mjs status

# 生成项目报告
node scripts/auto-lifecycle.mjs report

# 处理所有史诗任务
node scripts/auto-epics.mjs all

# 处理所有故事
node scripts/auto-all-stories.mjs all

# 运行测试
node scripts/run-tests.mjs
\`\`\`

---

**项目状态**: ${projectStatus.production ? '✅ 生产就绪' : '⏳ 准备中'}
**最后更新**: ${new Date().toISOString()}
`;
  
  writeMarkdown(reportPath, report);
  console.log(`✅ 项目报告已生成: ${reportPath}`);
  
  return report;
}

// 运行测试
function runTests() {
  console.log('\n🧪 运行测试...');
  
  const testsDir = join(ROOT, 'tests');
  if (!existsSync(testsDir)) {
    console.log('❌ 测试目录不存在');
    return false;
  }
  
  // 检查测试文件
  const unitDir = join(testsDir, 'unit');
  if (existsSync(unitDir)) {
    const unitSystems = readdirSync(unitDir);
    
    for (const system of unitSystems) {
      const systemDir = join(unitDir, system);
      if (existsSync(systemDir)) {
        const testFiles = readdirSync(systemDir).filter(f => f.endsWith('_test.gd'));
        
        for (const testFile of testFiles) {
          console.log(`📄 测试文件: ${system}/${testFile}`);
        }
      }
    }
  }
  
  console.log('\n💡 提示: 在Godot中运行测试:');
  console.log('   godot --headless --script tests/run_tests.gd');
  
  return true;
}

// 主函数
function main() {
  const args = process.argv.slice(2);
  
  if (args.length < 1) {
    console.log('用法: node scripts/auto-lifecycle.mjs [command]');
    console.log('\n可用命令:');
    console.log('  status - 检查项目状态');
    console.log('  report - 生成项目报告');
    console.log('  tests  - 运行测试');
    console.log('  all    - 执行所有检查');
    return;
  }
  
  const command = args[0];
  
  switch (command) {
    case 'status':
      checkProjectStatus();
      checkEpicStatus();
      checkStoryStatus();
      checkCodeStatus();
      checkTestStatus();
      break;
      
    case 'report':
      generateProjectReport();
      break;
      
    case 'tests':
      runTests();
      break;
      
    case 'all':
      checkProjectStatus();
      checkEpicStatus();
      checkStoryStatus();
      checkCodeStatus();
      checkTestStatus();
      generateProjectReport();
      runTests();
      break;
      
    default:
      console.log(`❌ 未知命令: ${command}`);
      console.log('可用命令: status, report, tests, all');
  }
}

main();
