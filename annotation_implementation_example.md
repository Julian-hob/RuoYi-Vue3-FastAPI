# 标注平台实现示例

## 1. 后端实现

### 1.1 创建标注模块

首先在 `ruoyi-fastapi-backend` 中创建新的标注模块：

```bash
mkdir -p module_annotation/{controller,service,dao,entity}
```

### 1.2 实体类定义

```python
# module_annotation/entity/annotation_project.py
from sqlalchemy import Column, Integer, String, Text, DateTime, BigInteger
from sqlalchemy.sql import func
from config.database import Base

class AnnotationProject(Base):
    __tablename__ = 'annotation_project'
    
    id = Column(BigInteger, primary_key=True, autoincrement=True)
    project_name = Column(String(100), nullable=False, comment='项目名称')
    project_type = Column(String(50), nullable=False, comment='标注类型')
    description = Column(Text, comment='项目描述')
    status = Column(String(20), default='active', comment='项目状态')
    created_by = Column(BigInteger, comment='创建人')
    created_time = Column(DateTime, default=func.now())
    updated_time = Column(DateTime, default=func.now(), onupdate=func.now())
```

```python
# module_annotation/entity/annotation_task.py
from sqlalchemy import Column, Integer, String, DateTime, BigInteger, DECIMAL
from sqlalchemy.sql import func
from config.database import Base

class AnnotationTask(Base):
    __tablename__ = 'annotation_task'
    
    id = Column(BigInteger, primary_key=True, autoincrement=True)
    project_id = Column(BigInteger, nullable=False, comment='项目ID')
    task_name = Column(String(100), nullable=False, comment='任务名称')
    assignee_id = Column(BigInteger, comment='标注员ID')
    reviewer_id = Column(BigInteger, comment='审核员ID')
    status = Column(String(20), default='pending', comment='任务状态')
    progress = Column(DECIMAL(5,2), default=0, comment='进度百分比')
    created_time = Column(DateTime, default=func.now())
```

### 1.3 数据访问层

```python
# module_annotation/dao/annotation_project_dao.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from module_annotation.entity.annotation_project import AnnotationProject
from typing import List, Optional

class AnnotationProjectDao:
    
    @staticmethod
    async def create_project(db: AsyncSession, project_data: dict) -> AnnotationProject:
        project = AnnotationProject(**project_data)
        db.add(project)
        await db.commit()
        await db.refresh(project)
        return project
    
    @staticmethod
    async def get_projects(db: AsyncSession, page: int = 1, size: int = 10) -> List[AnnotationProject]:
        offset = (page - 1) * size
        result = await db.execute(
            select(AnnotationProject)
            .offset(offset)
            .limit(size)
            .order_by(AnnotationProject.created_time.desc())
        )
        return result.scalars().all()
    
    @staticmethod
    async def get_project_by_id(db: AsyncSession, project_id: int) -> Optional[AnnotationProject]:
        result = await db.execute(
            select(AnnotationProject).where(AnnotationProject.id == project_id)
        )
        return result.scalar_one_or_none()
```

### 1.4 服务层

```python
# module_annotation/service/annotation_project_service.py
from sqlalchemy.ext.asyncio import AsyncSession
from module_annotation.dao.annotation_project_dao import AnnotationProjectDao
from module_annotation.entity.vo.project_vo import ProjectCreate, ProjectUpdate
from typing import List, Optional

class AnnotationProjectService:
    
    @staticmethod
    async def create_project_service(db: AsyncSession, project: ProjectCreate, user_id: int) -> dict:
        project_data = {
            'project_name': project.project_name,
            'project_type': project.project_type,
            'description': project.description,
            'created_by': user_id
        }
        result = await AnnotationProjectDao.create_project(db, project_data)
        return {
            'id': result.id,
            'project_name': result.project_name,
            'project_type': result.project_type,
            'status': result.status
        }
    
    @staticmethod
    async def get_projects_service(db: AsyncSession, page: int = 1, size: int = 10) -> dict:
        projects = await AnnotationProjectDao.get_projects(db, page, size)
        return {
            'list': [{
                'id': p.id,
                'project_name': p.project_name,
                'project_type': p.project_type,
                'status': p.status,
                'created_time': p.created_time.strftime('%Y-%m-%d %H:%M:%S')
            } for p in projects],
            'total': len(projects)
        }
```

### 1.5 控制器层

```python
# module_annotation/controller/annotation_project_controller.py
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from config.get_db import get_db
from module_admin.service.login_service import get_current_user
from module_annotation.entity.vo.project_vo import ProjectCreate, ProjectResponse
from module_annotation.service.annotation_project_service import AnnotationProjectService
from utils.response_util import ResponseUtil

annotationProjectController = APIRouter()

@annotationProjectController.post('/projects', response_model=ProjectResponse)
async def create_project(
    project: ProjectCreate,
    current_user = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """创建标注项目"""
    result = await AnnotationProjectService.create_project_service(db, project, current_user.user.user_id)
    return ResponseUtil.success(data=result, msg='项目创建成功')

@annotationProjectController.get('/projects')
async def get_projects(
    page: int = Query(1, ge=1),
    size: int = Query(10, ge=1, le=100),
    db: AsyncSession = Depends(get_db)
):
    """获取项目列表"""
    result = await AnnotationProjectService.get_projects_service(db, page, size)
    return ResponseUtil.success(data=result)
```

### 1.6 数据模型

```python
# module_annotation/entity/vo/project_vo.py
from pydantic import BaseModel
from typing import Optional

class ProjectCreate(BaseModel):
    project_name: str
    project_type: str
    description: Optional[str] = None

class ProjectUpdate(BaseModel):
    project_name: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None

class ProjectResponse(BaseModel):
    id: int
    project_name: str
    project_type: str
    status: str
```

## 2. 前端实现

### 2.1 创建标注模块路由

```javascript
// src/router/modules/annotation.js
export default {
  path: '/annotation',
  component: () => import('@/layout/index'),
  redirect: '/annotation/project',
  name: 'Annotation',
  meta: {
    title: '标注管理',
    icon: 'edit'
  },
  children: [
    {
      path: 'project',
      name: 'AnnotationProject',
      component: () => import('@/views/annotation/project/index'),
      meta: { title: '项目管理', icon: 'project' }
    },
    {
      path: 'task',
      name: 'AnnotationTask', 
      component: () => import('@/views/annotation/task/index'),
      meta: { title: '任务管理', icon: 'task' }
    },
    {
      path: 'workspace',
      name: 'AnnotationWorkspace',
      component: () => import('@/views/annotation/workspace/index'),
      meta: { title: '标注工作台', icon: 'edit' }
    }
  ]
}
```

### 2.2 API接口定义

```javascript
// src/api/annotation/project.js
import request from '@/utils/request'

// 获取项目列表
export function getProjectList(query) {
  return request({
    url: '/annotation/projects',
    method: 'get',
    params: query
  })
}

// 创建项目
export function createProject(data) {
  return request({
    url: '/annotation/projects',
    method: 'post',
    data: data
  })
}

// 更新项目
export function updateProject(id, data) {
  return request({
    url: `/annotation/projects/${id}`,
    method: 'put',
    data: data
  })
}

// 删除项目
export function deleteProject(id) {
  return request({
    url: `/annotation/projects/${id}`,
    method: 'delete'
  })
}
```

### 2.3 项目管理页面

```vue
<!-- src/views/annotation/project/index.vue -->
<template>
  <div class="app-container">
    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="项目名称" prop="projectName">
        <el-input
          v-model="queryParams.projectName"
          placeholder="请输入项目名称"
          clearable
          style="width: 200px"
          @keyup.enter="handleQuery"
        />
      </el-form-item>
      <el-form-item label="项目类型" prop="projectType">
        <el-select v-model="queryParams.projectType" placeholder="请选择项目类型" clearable style="width: 200px">
          <el-option label="图像分类" value="classification" />
          <el-option label="目标检测" value="detection" />
          <el-option label="语义分割" value="segmentation" />
          <el-option label="OCR识别" value="ocr" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button
          type="primary"
          plain
          icon="Plus"
          @click="handleAdd"
          v-hasPermi="['annotation:project:add']"
        >新增</el-button>
      </el-col>
    </el-row>

    <el-table v-loading="loading" :data="projectList">
      <el-table-column label="项目ID" align="center" prop="id" />
      <el-table-column label="项目名称" align="center" prop="projectName" />
      <el-table-column label="项目类型" align="center" prop="projectType">
        <template #default="scope">
          <el-tag :type="getProjectTypeTag(scope.row.projectType)">
            {{ getProjectTypeLabel(scope.row.projectType) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="状态" align="center" prop="status">
        <template #default="scope">
          <el-tag :type="scope.row.status === 'active' ? 'success' : 'info'">
            {{ scope.row.status === 'active' ? '进行中' : '已完成' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="创建时间" align="center" prop="createdTime" width="180" />
      <el-table-column label="操作" align="center" class-name="small-padding fixed-width">
        <template #default="scope">
          <el-button
            type="text"
            icon="Edit"
            @click="handleUpdate(scope.row)"
            v-hasPermi="['annotation:project:edit']"
          >修改</el-button>
          <el-button
            type="text"
            icon="Delete"
            @click="handleDelete(scope.row)"
            v-hasPermi="['annotation:project:remove']"
          >删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination
      v-show="total>0"
      :total="total"
      v-model:page="queryParams.pageNum"
      v-model:limit="queryParams.pageSize"
      @pagination="getList"
    />

    <!-- 添加或修改项目对话框 -->
    <el-dialog :title="title" v-model="open" width="500px" append-to-body>
      <el-form ref="projectRef" :model="form" :rules="rules" label-width="80px">
        <el-form-item label="项目名称" prop="projectName">
          <el-input v-model="form.projectName" placeholder="请输入项目名称" />
        </el-form-item>
        <el-form-item label="项目类型" prop="projectType">
          <el-select v-model="form.projectType" placeholder="请选择项目类型">
            <el-option label="图像分类" value="classification" />
            <el-option label="目标检测" value="detection" />
            <el-option label="语义分割" value="segmentation" />
            <el-option label="OCR识别" value="ocr" />
          </el-select>
        </el-form-item>
        <el-form-item label="项目描述" prop="description">
          <el-input v-model="form.description" type="textarea" placeholder="请输入项目描述" />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button type="primary" @click="submitForm">确 定</el-button>
          <el-button @click="cancel">取 消</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup name="AnnotationProject">
import { getProjectList, createProject, updateProject, deleteProject } from '@/api/annotation/project'

const { proxy } = getCurrentInstance()
const { sys_normal_dict } = proxy.useDict("sys_normal_dict")

const projectList = ref([])
const open = ref(false)
const loading = ref(true)
const showSearch = ref(true)
const ids = ref([])
const single = ref(true)
const multiple = ref(true)
const total = ref(0)
const title = ref("")

const data = reactive({
  form: {},
  queryParams: {
    pageNum: 1,
    pageSize: 10,
    projectName: undefined,
    projectType: undefined
  },
  rules: {
    projectName: [
      { required: true, message: "项目名称不能为空", trigger: "blur" }
    ],
    projectType: [
      { required: true, message: "项目类型不能为空", trigger: "change" }
    ]
  }
})

const { queryParams, form, rules } = toRefs(data)

/** 查询项目列表 */
function getList() {
  loading.value = true
  getProjectList(queryParams.value).then(response => {
    projectList.value = response.data.list
    total.value = response.data.total
    loading.value = false
  })
}

/** 搜索按钮操作 */
function handleQuery() {
  queryParams.value.pageNum = 1
  getList()
}

/** 重置按钮操作 */
function resetQuery() {
  proxy.resetForm("queryRef")
  handleQuery()
}

/** 新增按钮操作 */
function handleAdd() {
  reset()
  open.value = true
  title.value = "添加项目"
}

/** 修改按钮操作 */
function handleUpdate(row) {
  reset()
  const id = row.id || ids.value
  getProject(id).then(response => {
    form.value = response.data
    open.value = true
    title.value = "修改项目"
  })
}

/** 提交按钮 */
function submitForm() {
  proxy.$refs["projectRef"].validate(valid => {
    if (valid) {
      if (form.value.id != null) {
        updateProject(form.value.id, form.value).then(response => {
          proxy.$modal.msgSuccess("修改成功")
          open.value = false
          getList()
        })
      } else {
        createProject(form.value).then(response => {
          proxy.$modal.msgSuccess("新增成功")
          open.value = false
          getList()
        })
      }
    }
  })
}

/** 删除按钮操作 */
function handleDelete(row) {
  const projectIds = row.id || ids.value
  proxy.$modal.confirm('是否确认删除项目编号为"' + projectIds + '"的数据项？').then(function() {
    return deleteProject(projectIds)
  }).then(() => {
    getList()
    proxy.$modal.msgSuccess("删除成功")
  }).catch(() => {})
}

/** 项目类型标签 */
function getProjectTypeTag(type) {
  const typeMap = {
    'classification': 'primary',
    'detection': 'success', 
    'segmentation': 'warning',
    'ocr': 'info'
  }
  return typeMap[type] || 'default'
}

/** 项目类型标签文本 */
function getProjectTypeLabel(type) {
  const typeMap = {
    'classification': '图像分类',
    'detection': '目标检测',
    'segmentation': '语义分割', 
    'ocr': 'OCR识别'
  }
  return typeMap[type] || type
}

getList()
</script>
```

### 2.4 标注工作台组件

```vue
<!-- src/views/annotation/workspace/index.vue -->
<template>
  <div class="annotation-workspace">
    <div class="workspace-header">
      <el-row :gutter="20">
        <el-col :span="8">
          <div class="task-info">
            <h3>当前任务: {{ currentTask.taskName }}</h3>
            <p>进度: {{ currentTask.progress }}%</p>
          </div>
        </el-col>
        <el-col :span="8">
          <div class="tool-panel">
            <el-button-group>
              <el-button 
                :type="currentTool === 'rectangle' ? 'primary' : ''"
                @click="setTool('rectangle')"
              >
                矩形框
              </el-button>
              <el-button 
                :type="currentTool === 'polygon' ? 'primary' : ''"
                @click="setTool('polygon')"
              >
                多边形
              </el-button>
              <el-button 
                :type="currentTool === 'point' ? 'primary' : ''"
                @click="setTool('point')"
              >
                关键点
              </el-button>
            </el-button-group>
          </div>
        </el-col>
        <el-col :span="8">
          <div class="action-panel">
            <el-button @click="saveAnnotation" type="success">保存</el-button>
            <el-button @click="nextImage" type="primary">下一张</el-button>
            <el-button @click="prevImage" type="info">上一张</el-button>
          </div>
        </el-col>
      </el-row>
    </div>

    <div class="workspace-content">
      <div class="image-container">
        <canvas 
          ref="canvas"
          @mousedown="onMouseDown"
          @mousemove="onMouseMove"
          @mouseup="onMouseUp"
          @keydown="onKeyDown"
          tabindex="0"
        ></canvas>
      </div>
      
      <div class="annotation-panel">
        <h4>标注结果</h4>
        <div class="annotation-list">
          <div 
            v-for="(annotation, index) in annotations" 
            :key="index"
            class="annotation-item"
            :class="{ active: selectedAnnotation === index }"
            @click="selectAnnotation(index)"
          >
            <span>{{ annotation.label }}</span>
            <el-button 
              size="small" 
              type="danger" 
              @click="removeAnnotation(index)"
            >
              删除
            </el-button>
          </div>
        </div>
        
        <div class="label-input">
          <el-input 
            v-model="newLabel" 
            placeholder="输入标签名称"
            @keyup.enter="addLabel"
          >
            <template #append>
              <el-button @click="addLabel">添加</el-button>
            </template>
          </el-input>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, nextTick } from 'vue'
import { fabric } from 'fabric'

const canvas = ref(null)
const fabricCanvas = ref(null)
const currentTool = ref('rectangle')
const currentTask = ref({
  taskName: '示例任务',
  progress: 25
})

const annotations = ref([])
const selectedAnnotation = ref(-1)
const newLabel = ref('')

const imageList = ref([
  '/api/annotation/images/1.jpg',
  '/api/annotation/images/2.jpg',
  '/api/annotation/images/3.jpg'
])
const currentImageIndex = ref(0)

// 初始化Canvas
onMounted(() => {
  initCanvas()
  loadImage()
})

function initCanvas() {
  fabricCanvas.value = new fabric.Canvas(canvas.value, {
    width: 800,
    height: 600
  })
  
  // 设置画布事件
  fabricCanvas.value.on('selection:created', onSelectionCreated)
  fabricCanvas.value.on('selection:cleared', onSelectionCleared)
}

function loadImage() {
  const img = new Image()
  img.onload = () => {
    fabricCanvas.value.clear()
    
    // 计算图片缩放比例
    const canvasWidth = fabricCanvas.value.width
    const canvasHeight = fabricCanvas.value.height
    const imgRatio = img.width / img.height
    const canvasRatio = canvasWidth / canvasHeight
    
    let scaleX, scaleY
    if (imgRatio > canvasRatio) {
      scaleX = canvasWidth / img.width
      scaleY = scaleX
    } else {
      scaleY = canvasHeight / img.height
      scaleX = scaleY
    }
    
    const fabricImage = new fabric.Image(img, {
      left: 0,
      top: 0,
      scaleX: scaleX,
      scaleY: scaleY
    })
    
    fabricCanvas.value.add(fabricImage)
    fabricCanvas.value.renderAll()
  }
  img.src = imageList.value[currentImageIndex.value]
}

function setTool(tool) {
  currentTool.value = tool
  fabricCanvas.value.isDrawingMode = false
  
  switch(tool) {
    case 'rectangle':
      fabricCanvas.value.defaultCursor = 'crosshair'
      break
    case 'polygon':
      fabricCanvas.value.defaultCursor = 'crosshair'
      break
    case 'point':
      fabricCanvas.value.defaultCursor = 'crosshair'
      break
  }
}

function onMouseDown(e) {
  if (currentTool.value === 'rectangle') {
    const pointer = fabricCanvas.value.getPointer(e.e)
    const rect = new fabric.Rect({
      left: pointer.x,
      top: pointer.y,
      width: 0,
      height: 0,
      fill: 'rgba(255, 0, 0, 0.3)',
      stroke: 'red',
      strokeWidth: 2
    })
    
    fabricCanvas.value.add(rect)
    fabricCanvas.value.setActiveObject(rect)
  }
}

function onMouseMove(e) {
  if (currentTool.value === 'rectangle' && fabricCanvas.value.getActiveObject()) {
    const pointer = fabricCanvas.value.getPointer(e.e)
    const rect = fabricCanvas.value.getActiveObject()
    
    if (rect.left > pointer.x) {
      rect.set({ left: pointer.x })
    }
    if (rect.top > pointer.y) {
      rect.set({ top: pointer.y })
    }
    
    rect.set({
      width: Math.abs(pointer.x - rect.left),
      height: Math.abs(pointer.y - rect.top)
    })
    
    fabricCanvas.value.renderAll()
  }
}

function onMouseUp(e) {
  if (currentTool.value === 'rectangle') {
    const rect = fabricCanvas.value.getActiveObject()
    if (rect && rect.width > 10 && rect.height > 10) {
      annotations.value.push({
        type: 'rectangle',
        label: '未命名',
        data: {
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height
        }
      })
    }
  }
}

function onKeyDown(e) {
  if (e.key === 'Delete' && selectedAnnotation.value >= 0) {
    removeAnnotation(selectedAnnotation.value)
  }
}

function selectAnnotation(index) {
  selectedAnnotation.value = index
}

function removeAnnotation(index) {
  annotations.value.splice(index, 1)
  selectedAnnotation.value = -1
}

function addLabel() {
  if (newLabel.value.trim() && selectedAnnotation.value >= 0) {
    annotations.value[selectedAnnotation.value].label = newLabel.value.trim()
    newLabel.value = ''
  }
}

function saveAnnotation() {
  // 保存标注结果到后端
  console.log('保存标注结果:', annotations.value)
}

function nextImage() {
  if (currentImageIndex.value < imageList.value.length - 1) {
    currentImageIndex.value++
    loadImage()
    annotations.value = []
  }
}

function prevImage() {
  if (currentImageIndex.value > 0) {
    currentImageIndex.value--
    loadImage()
    annotations.value = []
  }
}
</script>

<style scoped>
.annotation-workspace {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.workspace-header {
  padding: 10px;
  border-bottom: 1px solid #ddd;
  background: #f5f5f5;
}

.workspace-content {
  flex: 1;
  display: flex;
  overflow: hidden;
}

.image-container {
  flex: 1;
  padding: 20px;
  display: flex;
  justify-content: center;
  align-items: center;
  background: #f0f0f0;
}

.image-container canvas {
  border: 1px solid #ddd;
  background: white;
}

.annotation-panel {
  width: 300px;
  padding: 20px;
  border-left: 1px solid #ddd;
  background: white;
}

.annotation-list {
  margin-bottom: 20px;
}

.annotation-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px;
  margin-bottom: 5px;
  border: 1px solid #ddd;
  border-radius: 4px;
  cursor: pointer;
}

.annotation-item.active {
  background: #e6f7ff;
  border-color: #1890ff;
}

.label-input {
  margin-top: 20px;
}
</style>
```

## 3. 集成到现有系统

### 3.1 在主应用中注册标注模块

```python
# 在 server.py 中添加标注模块路由
from module_annotation.controller.annotation_project_controller import annotationProjectController
from module_annotation.controller.annotation_task_controller import annotationTaskController

# 添加到控制器列表
controller_list.extend([
    {'router': annotationProjectController, 'tags': ['标注管理-项目管理']},
    {'router': annotationTaskController, 'tags': ['标注管理-任务管理']},
])
```

### 3.2 添加权限配置

```sql
-- 在数据库中添加标注相关权限
INSERT INTO sys_menu VALUES (2000, '标注管理', 0, 4, 'annotation', NULL, NULL, 1, 0, 'M', '0', '0', '', 'edit', 'admin', NOW(), '', NULL, '标注管理目录');
INSERT INTO sys_menu VALUES (2001, '项目管理', 2000, 1, 'project', 'annotation/project/index', NULL, 1, 0, 'C', '0', '0', 'annotation:project:list', 'project', 'admin', NOW(), '', NULL, '项目管理菜单');
INSERT INTO sys_menu VALUES (2002, '任务管理', 2000, 2, 'task', 'annotation/task/index', NULL, 1, 0, 'C', '0', '0', 'annotation:task:list', 'task', 'admin', NOW(), '', NULL, '任务管理菜单');
INSERT INTO sys_menu VALUES (2003, '标注工作台', 2000, 3, 'workspace', 'annotation/workspace/index', NULL, 1, 0, 'C', '0', '0', 'annotation:workspace:list', 'edit', 'admin', NOW(), '', NULL, '标注工作台菜单');
```

这个实现示例展示了如何在现有RuoYi框架基础上快速构建一个功能完整的标注平台。通过复用现有的用户管理、权限控制、日志系统等功能，可以大大减少开发工作量，同时保持系统的一致性和可维护性。