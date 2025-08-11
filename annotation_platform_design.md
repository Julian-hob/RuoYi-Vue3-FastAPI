# 人工标注平台设计方案

## 1. 系统架构

### 1.1 整体架构
```
前端 (Vue3 + Element Plus)
    ↓
API网关 (FastAPI)
    ↓
业务服务层
├── 项目管理服务
├── 标注任务服务  
├── 标注工具服务
├── 审核服务
└── 数据导出服务
    ↓
数据层
├── MySQL (项目、任务、用户数据)
├── Redis (缓存、会话)
└── 文件存储 (标注数据、原始文件)
```

### 1.2 核心模块设计

#### 项目管理模块
- 项目创建、配置、状态管理
- 标注类型配置 (分类、检测、分割、OCR等)
- 数据集管理
- 标注规范制定

#### 标注任务模块
- 任务分配和调度
- 标注进度跟踪
- 质量控制
- 标注员管理

#### 标注工具模块
- 图像标注工具 (矩形框、多边形、关键点)
- 文本标注工具 (命名实体、关系抽取)
- 视频标注工具 (时序标注)
- 音频标注工具

#### 审核模块
- 标注质量审核
- 审核流程管理
- 争议处理
- 质量评估

## 2. 数据库设计

### 2.1 核心表结构

```sql
-- 项目表
CREATE TABLE annotation_project (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    project_name VARCHAR(100) NOT NULL COMMENT '项目名称',
    project_type VARCHAR(50) NOT NULL COMMENT '标注类型',
    description TEXT COMMENT '项目描述',
    status VARCHAR(20) DEFAULT 'active' COMMENT '项目状态',
    created_by BIGINT COMMENT '创建人',
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 数据集表
CREATE TABLE annotation_dataset (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    project_id BIGINT NOT NULL COMMENT '项目ID',
    dataset_name VARCHAR(100) NOT NULL COMMENT '数据集名称',
    data_type VARCHAR(20) NOT NULL COMMENT '数据类型',
    total_count INT DEFAULT 0 COMMENT '总数量',
    annotated_count INT DEFAULT 0 COMMENT '已标注数量',
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 标注任务表
CREATE TABLE annotation_task (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    project_id BIGINT NOT NULL COMMENT '项目ID',
    dataset_id BIGINT NOT NULL COMMENT '数据集ID',
    task_name VARCHAR(100) NOT NULL COMMENT '任务名称',
    assignee_id BIGINT COMMENT '标注员ID',
    reviewer_id BIGINT COMMENT '审核员ID',
    status VARCHAR(20) DEFAULT 'pending' COMMENT '任务状态',
    progress DECIMAL(5,2) DEFAULT 0 COMMENT '进度百分比',
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 标注数据表
CREATE TABLE annotation_data (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_id BIGINT NOT NULL COMMENT '任务ID',
    data_path VARCHAR(500) NOT NULL COMMENT '数据路径',
    annotation_result JSON COMMENT '标注结果',
    status VARCHAR(20) DEFAULT 'pending' COMMENT '标注状态',
    annotated_by BIGINT COMMENT '标注员ID',
    reviewed_by BIGINT COMMENT '审核员ID',
    created_time DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 3. 前端界面设计

### 3.1 主要页面

#### 项目管理页面
- 项目列表展示
- 项目创建向导
- 项目配置界面
- 数据统计面板

#### 标注工作台
- 数据展示区域
- 标注工具面板
- 标注结果展示
- 快捷键支持

#### 审核工作台
- 标注结果预览
- 审核操作面板
- 质量评估界面
- 争议处理界面

### 3.2 标注工具组件

#### 图像标注工具
```vue
<template>
  <div class="image-annotation-tool">
    <canvas ref="canvas" @mousedown="onMouseDown" @mousemove="onMouseMove" @mouseup="onMouseUp"></canvas>
    <div class="tool-panel">
      <el-button-group>
        <el-button @click="setTool('rectangle')">矩形框</el-button>
        <el-button @click="setTool('polygon')">多边形</el-button>
        <el-button @click="setTool('point')">关键点</el-button>
      </el-button-group>
    </div>
  </div>
</template>
```

## 4. 后端API设计

### 4.1 项目管理API
```python
@router.post("/projects")
async def create_project(project: ProjectCreate, current_user: User = Depends(get_current_user)):
    """创建标注项目"""
    pass

@router.get("/projects")
async def get_projects(page: int = 1, size: int = 10):
    """获取项目列表"""
    pass

@router.get("/projects/{project_id}/statistics")
async def get_project_statistics(project_id: int):
    """获取项目统计信息"""
    pass
```

### 4.2 标注任务API
```python
@router.post("/tasks")
async def create_task(task: TaskCreate):
    """创建标注任务"""
    pass

@router.get("/tasks/assign")
async def get_assigned_tasks(current_user: User = Depends(get_current_user)):
    """获取分配给当前用户的任务"""
    pass

@router.post("/tasks/{task_id}/annotate")
async def submit_annotation(task_id: int, annotation: AnnotationResult):
    """提交标注结果"""
    pass
```

### 4.3 数据管理API
```python
@router.post("/datasets/upload")
async def upload_dataset(file: UploadFile, project_id: int):
    """上传数据集"""
    pass

@router.get("/datasets/{dataset_id}/data")
async def get_dataset_data(dataset_id: int, page: int = 1, size: int = 20):
    """获取数据集数据"""
    pass
```

## 5. 核心功能实现

### 5.1 标注工具实现
- 使用Canvas API实现图像标注
- 支持多种标注类型
- 实时保存标注结果
- 支持撤销和重做

### 5.2 任务调度算法
- 基于工作量的任务分配
- 考虑标注员专业领域
- 动态调整任务优先级
- 负载均衡机制

### 5.3 质量控制
- 标注一致性检查
- 审核流程管理
- 质量评估指标
- 争议处理机制

## 6. 扩展功能

### 6.1 AI辅助标注
- 预标注功能
- 智能建议
- 自动质量检查
- 标注效率优化

### 6.2 数据导出
- 多种格式支持 (COCO, YOLO, Pascal VOC等)
- 批量导出功能
- 数据格式转换
- 质量报告生成

### 6.3 性能优化
- 图片懒加载
- 标注结果缓存
- 异步处理
- CDN加速

## 7. 部署方案

### 7.1 开发环境
```bash
# 前端开发
cd annotation-frontend
npm install
npm run dev

# 后端开发
cd annotation-backend
pip install -r requirements.txt
python app.py --env=dev
```

### 7.2 生产环境
- Docker容器化部署
- Nginx反向代理
- Redis集群
- MySQL主从复制

## 8. 技术选型建议

### 8.1 标注工具库
- **图像标注**: Fabric.js, Konva.js
- **视频标注**: Video.js
- **文本标注**: 自定义组件
- **音频标注**: Web Audio API

### 8.2 文件存储
- **本地存储**: 开发环境
- **对象存储**: 生产环境 (阿里云OSS, AWS S3)
- **CDN**: 静态资源加速

### 8.3 监控和日志
- 标注进度监控
- 用户行为分析
- 系统性能监控
- 错误日志收集