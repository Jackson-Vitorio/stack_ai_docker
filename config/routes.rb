Rails.application.routes.draw do

  get '/spells/centro', to: 'spells#centro'
  get '/spells/magias', to: 'spells#magias'
  get '/spells/monstros', to: 'spells#monstros'
  get '/spells/styles', to: 'spells#styles'

end
