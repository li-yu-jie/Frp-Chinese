<template>
  <div class="configure-page">
    <el-card class="main-card" shadow="never">
      <div class="toolbar-header">
        <h2 class="card-title">客户端配置</h2>
        <div class="toolbar-actions">
          <el-tooltip content="刷新" placement="top">
            <el-button :icon="Refresh" circle @click="fetchData" />
          </el-tooltip>
          <el-button type="primary" :icon="Upload" @click="handleUpload">更新</el-button>
        </div>
      </div>

      <div class="config-editor">
        <el-input
          type="textarea"
          :autosize="{ minRows: 10, maxRows: 30 }"
          v-model="configContent"
          placeholder="frpc 客户端配置内容..."
          class="code-input"
        ></el-input>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Refresh, Upload } from '@element-plus/icons-vue'
import { getConfig, putConfig, reloadConfig } from '../api/frpc'

const configContent = ref('')

const fetchData = async () => {
  try {
    const text = await getConfig()
    configContent.value = text
  } catch (err: any) {
    ElMessage({
      showClose: true,
      message: '获取客户端配置失败！' + err.message,
      type: 'warning',
    })
  }
}

const handleUpload = () => {
  ElMessageBox.confirm(
    '此操作将更新客户端配置并重新加载，是否继续？',
    '确认更新',
    {
      confirmButtonText: '更新',
      cancelButtonText: '取消',
      type: 'warning',
    }
  )
    .then(async () => {
      if (!configContent.value.trim()) {
        ElMessage({
          message: '客户端配置内容不能为空！',
          type: 'warning',
        })
        return
      }

      try {
        await putConfig(configContent.value)
        await reloadConfig()
        ElMessage({
          type: 'success',
          message: '客户端配置更新并重新加载成功！',
        })
      } catch (err: any) {
        ElMessage({
          showClose: true,
          message: '更新客户端配置失败！' + err.message,
          type: 'error',
        })
      }
    })
    .catch(() => {
        // cancelled
    })
}

fetchData()
</script>

<style scoped>
.main-card {
  border-radius: 12px;
  border: none;
}

.toolbar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  border-bottom: 1px solid var(--el-border-color-lighter);
  padding-bottom: 16px;
}

.card-title {
    margin: 0;
    font-size: 18px;
    font-weight: 600;
}

.code-input {
    font-family: 'Menlo', 'Monaco', 'Courier New', monospace;
    font-size: 14px;
}
</style>