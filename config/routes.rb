CoverTest::Application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  root 'covers#index'
  get 'covers/:isbn13/(:filter)' => 'covers#show', as: 'cover', constraints: { isbn13: /\d{13}/ }
  get 'quality/:quality/(:filter)' => 'covers#quality', as: 'quality', constraints: { quality: /1?\d{2}/ }
  get 'exceptions' => 'covers#exceptions', as: 'exceptions'

end
