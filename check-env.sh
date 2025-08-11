#!/bin/bash

# RuoYi-Vue3-FastAPI 环境检查脚本
# 作者: AI Assistant
# 版本: 1.0.0

echo "🔍 检查 RuoYi-Vue3-FastAPI 项目环境..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查函数
check_command() {
    local cmd=$1
    local name=$2
    local required_version=$3
    
    if command -v $cmd &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n 1)
        echo -e "${GREEN}✅ $name: $version${NC}"
        return 0
    else
        echo -e "${RED}❌ $name: 未安装${NC}"
        return 1
    fi
}

check_file() {
    local file=$1
    local name=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $name: 存在${NC}"
        return 0
    else
        echo -e "${RED}❌ $name: 不存在${NC}"
        return 1
    fi
}

check_directory() {
    local dir=$1
    local name=$2
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅ $name: 存在${NC}"
        return 0
    else
        echo -e "${RED}❌ $name: 不存在${NC}"
        return 1
    fi
}

echo ""
echo "📋 系统环境检查:"
echo "=================="

# 检查Python
check_command "python3" "Python3" "3.9+"

# 检查Node.js
check_command "node" "Node.js" "16+"

# 检查npm
check_command "npm" "npm" "8+"

# 检查Git
check_command "git" "Git" ""

echo ""
echo "📋 项目文件检查:"
echo "=================="

# 检查项目目录
check_directory "ruoyi-fastapi-backend" "后端项目目录"
check_directory "ruoyi-fastapi-frontend" "前端项目目录"

# 检查后端文件
if [ -d "ruoyi-fastapi-backend" ]; then
    check_file "ruoyi-fastapi-backend/requirements.txt" "后端依赖文件"
    check_file "ruoyi-fastapi-backend/app.py" "后端入口文件"
    check_file "ruoyi-fastapi-backend/.env.dev" "后端开发环境配置"
    check_directory "ruoyi-fastapi-backend/sql" "数据库脚本目录"
fi

# 检查前端文件
if [ -d "ruoyi-fastapi-frontend" ]; then
    check_file "ruoyi-fastapi-frontend/package.json" "前端依赖文件"
    check_file "ruoyi-fastapi-frontend/vite.config.js" "前端构建配置"
    check_file "ruoyi-fastapi-frontend/.env.development" "前端开发环境配置"
fi

echo ""
echo "📋 数据库服务检查:"
echo "=================="

# 检查MySQL
if command -v mysql &> /dev/null; then
    echo -e "${GREEN}✅ MySQL: 已安装${NC}"
    # 尝试连接MySQL
    if mysql -u root -p -e "SELECT 1;" &> /dev/null; then
        echo -e "${GREEN}✅ MySQL: 连接正常${NC}"
    else
        echo -e "${YELLOW}⚠️  MySQL: 无法连接，请检查服务状态${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  MySQL: 未安装或不在PATH中${NC}"
fi

# 检查PostgreSQL
if command -v psql &> /dev/null; then
    echo -e "${GREEN}✅ PostgreSQL: 已安装${NC}"
    # 尝试连接PostgreSQL
    if psql -U postgres -c "SELECT 1;" &> /dev/null; then
        echo -e "${GREEN}✅ PostgreSQL: 连接正常${NC}"
    else
        echo -e "${YELLOW}⚠️  PostgreSQL: 无法连接，请检查服务状态${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  PostgreSQL: 未安装或不在PATH中${NC}"
fi

echo ""
echo "📋 Redis服务检查:"
echo "=================="

# 检查Redis
if command -v redis-cli &> /dev/null; then
    echo -e "${GREEN}✅ Redis: 已安装${NC}"
    # 尝试连接Redis
    if redis-cli ping &> /dev/null; then
        echo -e "${GREEN}✅ Redis: 连接正常${NC}"
    else
        echo -e "${YELLOW}⚠️  Redis: 无法连接，请检查服务状态${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Redis: 未安装或不在PATH中${NC}"
fi

echo ""
echo "📋 依赖安装检查:"
echo "=================="

# 检查后端依赖
if [ -d "ruoyi-fastapi-backend/venv" ]; then
    echo -e "${GREEN}✅ 后端虚拟环境: 已创建${NC}"
    if [ -f "ruoyi-fastapi-backend/venv/lib/python*/site-packages/fastapi" ]; then
        echo -e "${GREEN}✅ 后端依赖: 已安装${NC}"
    else
        echo -e "${YELLOW}⚠️  后端依赖: 未安装，请运行 pip install -r requirements.txt${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  后端虚拟环境: 未创建${NC}"
fi

# 检查前端依赖
if [ -d "ruoyi-fastapi-frontend/node_modules" ]; then
    echo -e "${GREEN}✅ 前端依赖: 已安装${NC}"
else
    echo -e "${YELLOW}⚠️  前端依赖: 未安装，请运行 npm install${NC}"
fi

echo ""
echo "📋 配置建议:"
echo "=================="

echo -e "${BLUE}💡 如果以上检查有未通过的项目，请按以下步骤操作:${NC}"
echo ""
echo "1. 安装缺失的软件:"
echo "   - Python3.9+: sudo apt install python3.9 python3.9-venv python3-pip"
echo "   - Node.js16+: curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash - && sudo apt-get install -y nodejs"
echo "   - MySQL: sudo apt install mysql-server"
echo "   - Redis: sudo apt install redis-server"
echo ""
echo "2. 启动数据库服务:"
echo "   - MySQL: sudo systemctl start mysql"
echo "   - Redis: sudo systemctl start redis"
echo ""
echo "3. 导入数据库:"
echo "   - MySQL: mysql -u root -p ruoyi-fastapi < ruoyi-fastapi-backend/sql/ruoyi-fastapi.sql"
echo "   - PostgreSQL: psql -U postgres -d ruoyi-fastapi -f ruoyi-fastapi-backend/sql/ruoyi-fastapi-pg.sql"
echo ""
echo "4. 安装项目依赖:"
echo "   - 后端: cd ruoyi-fastapi-backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
echo "   - 前端: cd ruoyi-fastapi-frontend && npm install"
echo ""
echo -e "${GREEN}🎉 环境检查完成！${NC}"