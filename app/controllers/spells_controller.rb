class SpellsController < ApplicationController
  require 'json'
  require 'rest-client'
  require 'yandex-translator'

  def magias
    return unless params[:spell_name].present?

    spell_name = params[:spell_name].gsub(' ', '-')
    response = RestClient.get "https://www.dnd5eapi.co/api/spells/#{spell_name}"
    data = JSON.parse(response.body)

    yandex_key = 'trnsl.1.1.20231003T122440Z.fced65d2902f6ce2.978b862b78445da0c72f0366ddfa549f43eb0d90'
    translator = Yandex::Translator.new(yandex_key)

    description = data['desc'][0]
    translated_description = translator.translate(description, from: 'en', to: 'pt')

    material = data['material']
    translated_material = translator.translate(material, from: 'en', to: 'pt')

    casting_time = data['casting_time']
    translated_casting_time = translator.translate(casting_time, from: 'en', to: 'pt')

    @spell_data = {
      'name' => data['name'],
      'description' => translated_description,
      'casting_time' => translated_casting_time,
      'material' => translated_material,
      'components' => data['components']
    }

    render 'magias'
  end

  def monstros
    return unless params[:monster_name].present?

    monster_name = params[:monster_name].gsub(' ', '-')
    response = RestClient.get "https://www.dnd5eapi.co/api/monsters/#{monster_name}"
    data = JSON.parse(response.body)

    yandex_key = 'trnsl.1.1.20231003T122440Z.fced65d2902f6ce2.978b862b78445da0c72f0366ddfa549f43eb0d90'
    translator = Yandex::Translator.new(yandex_key)

    name = data['name']
    translated_name = translator.translate(name, from: 'en', to: 'pt')

    size = data['size']
    translated_size = translator.translate(size, from: 'en', to: 'pt')

    type = data['type']
    translated_type = translator.translate(type, from: 'en', to: 'pt')

    armor_class = data['armor_class']

    hit_points = data['hit_points']

    actions = data['actions']
    translated_actions = []

    if actions.present?
      translated_actions = actions.map do |action|
        action_name = action['name']
        translated_action_name = translator.translate(action_name, from: 'en', to: 'pt')
        action_description = action['desc'] # Não usamos join nesta versão
        translated_action_description = translator.translate(action_description, from: 'en', to: 'pt')
        "#{translated_action_name}: #{translated_action_description}"
      end
    end

    @monster_data = {
      'name' => translated_name,
      'size' => translated_size,
      'type' => translated_type,
      'armor_class' => armor_class,
      'hit_points' => hit_points,
      'actions' => translated_actions
    }

    render 'monstros'
  end
end
