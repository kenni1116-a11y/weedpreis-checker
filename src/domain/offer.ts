export type FulfillmentMode = 'shipping' | 'pickup'
export type SourceType = 'feed' | 'public-source' | 'manual-review'
export type ProductForm = 'flower' | 'extract'
export type QuantityUnit = 'g' | 'ml'

export interface PricingContext {
  mode: FulfillmentMode
  quantity: number
}

export interface Offer {
  id: string; productId: string; productName: string; manufacturer: string
  form: ProductForm; thcPercent: number; cbdPercent: number
  pharmacyId: string; pharmacyName: string; sourceType: SourceType; sourceUrl: string
  unitPriceCents: number; priceUnit: QuantityUnit; shippingCents: number; pickup: boolean; shipping: boolean
  available: boolean; checkedAt: string; distanceMeters?: number
}

export interface OfferQuery extends PricingContext {
  text?: string; postalCode?: string
  form?: ProductForm; minThcPercent?: number
}

export interface RankedOffer {
  offer: Offer; totalPriceCents: number; current: boolean
}
