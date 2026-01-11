<template>
  <div class="clients-page">
    <div class="filter-bar">
      <el-input
        v-model="searchText"
        placeholder="按主机名、用户、客户端ID、运行ID搜索..."
        :prefix-icon="Search"
        clearable
        class="search-input"
      />
      <el-radio-group v-model="statusFilter" class="status-filter">
        <el-radio-button label="all">全部 ({{ stats.total }})</el-radio-button>
        <el-radio-button label="online">
          在线 ({{ stats.online }})
        </el-radio-button>
        <el-radio-button label="offline">
          离线 ({{ stats.offline }})
        </el-radio-button>
      </el-radio-group>
    </div>

    <div v-loading="loading" class="clients-grid">
      <el-empty
        v-if="filteredClients.length === 0 && !loading"
        description="未找到客户端"
      />
      <ClientCard
        v-for="client in filteredClients"
        :key="client.key"
        :client="client"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import { Client } from '../utils/client'
import ClientCard from '../components/ClientCard.vue'
import { getClients } from '../api/client'

const clients = ref<Client[]>([])
const loading = ref(false)
const searchText = ref('')
const statusFilter = ref<'all' | 'online' | 'offline'>('all')

let refreshTimer: number | null = null

const stats = computed(() => {
  const total = clients.value.length
  const online = clients.value.filter((c) => c.online).length
  const offline = total - online
  return { total, online, offline }
})

const filteredClients = computed(() => {
  let result = clients.value

  // 按状态过滤
  if (statusFilter.value === 'online') {
    result = result.filter((c) => c.online)
  } else if (statusFilter.value === 'offline') {
    result = result.filter((c) => !c.online)
  }

  // 按搜索文本过滤
  if (searchText.value) {
    result = result.filter((c) => c.matchesFilter(searchText.value))
  }

  // 排序: 在线优先，然后按显示名称排序
  result.sort((a, b) => {
    if (a.online !== b.online) {
      return a.online ? -1 : 1
    }
    return a.displayName.localeCompare(b.displayName)
  })

  return result
})

const fetchData = async () => {
  loading.value = true
  try {
    const json = await getClients()
    clients.value = json.map((data) => new Client(data))
  } catch (error: any) {
    console.error('获取客户端失败:', error)
    ElMessage({
      showClose: true,
      message: '获取客户端失败: ' + error.message,
      type: 'error',
    })
  } finally {
    loading.value = false
  }
}

const startAutoRefresh = () => {
  // 每5秒自动刷新
  refreshTimer = window.setInterval(() => {
    fetchData()
  }, 5000)
}

const stopAutoRefresh = () => {
  if (refreshTimer !== null) {
    window.clearInterval(refreshTimer)
    refreshTimer = null
  }
}

onMounted(() => {
  fetchData()
  startAutoRefresh()
})

onUnmounted(() => {
  stopAutoRefresh()
})
</script>

<style scoped>
.clients-page {
  padding: 0 20px 20px 20px;
}

.filter-bar {
  display: flex;
  gap: 16px;
  align-items: center;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.search-input {
  flex: 1;
  min-width: 300px;
  max-width: 500px;
}

.status-filter {
  flex-shrink: 0;
}

.clients-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
  gap: 20px;
  min-height: 200px;
}

@media (max-width: 768px) {
  .clients-grid {
    grid-template-columns: 1fr;
  }

  .filter-bar {
    flex-direction: column;
    align-items: stretch;
  }

  .search-input {
    max-width: none;
  }
}
</style>
