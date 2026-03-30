export type StockType = { id: string; name: string }

export type StockFormat = {
  id: string
  label: string
  volumeMl: number
  alcoholPercent: number
}

export type StockProductView = {
  id: string
  name: string
  description: string
  typeName: string
  formatLabel: string
  quantity: number
  imageKey: string
}

