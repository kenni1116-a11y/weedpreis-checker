export type FulfillmentMode = 'shipping' | 'pickup'
export type SourceType = 'feed' | 'public-source' | 'manual-review'
export type ProductForm = 'flower' | 'extract'

export interface Offer {
  id: string; productId: string; productName: string; manufacturer: string
  form: ProductForm; thcPercent: number; cbdPercent: number
  pharmacyId: string; pharmacyName: string; sourceType: SourceType; sourceUrl: string
  unitPriceCents: number; shippingCents: number; pickup: boolean; shipping: boolean
  available: boolean; checkedAt: string; distanceMeters?: number
}

export interface OfferQuery {
  mode: FulfillmentMode; grams: number; text?: string; postalCode?: string
  form?: ProductForm; minThcPercent?: number
}

export interface RankedOffer {
  offer: Offer; totalPriceCents: number; current: boolean
}
