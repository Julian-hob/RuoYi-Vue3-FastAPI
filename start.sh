#!/bin/bash

# RuoYi-Vue3-FastAPI 项目启动脚本
# 作者: AI Assistant
# 版本: 1.0.0

echo "🚀 启动 RuoYi-Vue3-FastAPI 项目..."

# 检查Python版本
echo "📋 检查Python版本..."
python3 --version

# 检查Node.js版本
echo "📋 检查Node.js版本..."
node --version

# 检查npm版本
echo "📋 检查npm版本..."
npm --version

# 启动后端
echo "🔧 启动后端服务..."
cd ruoyi-fastapi-backend

# 检查虚拟环境是否存在
if [ ! -d "venv" ]; then
    echo "📦 创建Python虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境
echo "🔧 激活虚拟环境..."
source venv/bin/activate

# 检查依赖是否安装
if [ ! -f "venv/lib/python*/site-packages/fastapi" ]; then
    echo "📦 安装Python依赖..."
    pip install -r requirements.txt
fi

# 启动后端服务（后台运行）
echo "🚀 启动后端服务 (端口: 9099)..."
python3 app.py --env=dev &
BACKEND_PID=$!

# 等待后端启动
sleep 3

# 启动前端
echo "🔧 启动前端服务..."
cd ../ruoyi-fastapi-frontend

# 检查node_modules是否存在
if [ ! -d "node_modules" ]; then
    echo "📦 安装前端依赖..."
    npm install
fi

# 启动前端服务（后台运行）
echo "🚀 启动前端服务 (端口: 80)..."
npm run dev &
FRONTEND_PID=$!

# 等待前端启动
sleep 5

echo ""
echo "🎉 项目启动完成！"
echo ""
echo "📱 访问地址:"
echo "   前端: http://localhost:80"
echo "   后端API: http://localhost:9099"
echo "   API文档: http://localhost:9099/docs"
echo ""
echo "🔑 默认登录信息:"
echo "   账号: admin"
echo "   密码: admin123"
echo ""
echo "⚠️  注意事项:"
echo "   1. 请确保MySQL/PostgreSQL数据库已启动"
echo "   2. 请确保Redis服务已启动"
echo "   3. 请确保已导入数据库脚本"
echo ""
echo "🛑 停止服务:"
echo "   按 Ctrl+C 停止所有服务"
echo ""

# 等待用户中断
trap "echo '🛑 正在停止服务...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT

# 保持脚本运行
wait