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
    casting_time = data['casting_time']
    translated_casting_time = translator.translate(casting_time, from: 'en', to: 'pt')
    if data.include?('components')
      material = data['material']
      begin
        translated_material = translator.translate(material, from: 'en', to: 'pt')
      rescue
        puts 'Erro de tradução'
        translated_material = material
      end
    else
      material = 'Não há material'
      translated_material = material
    end

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

 
    translated_name = translator.translate(data['name'], from: 'en', to: 'pt')
    translated_size = translator.translate(data['size'], from: 'en', to: 'pt')
    translated_type = translator.translate(data['type'], from: 'en', to: 'pt')

    armor = data['armor_class']
    armor_class = armor[0]['value']

    hit_points = data['hit_points']

    proficiencies = data['proficiencies'].map do |proficiency_data|
      value = proficiency_data['value']
      proficiency_name = proficiency_data['proficiency']['name']
      translated_proficiency_name = translator.translate(proficiency_name, from: 'en', to: 'pt')
      { 'value' => value, 'proficiency_name' => translated_proficiency_name }
    end

    special_abilities = data['special_abilities'].map do |ability_data|
      name = ability_data['name']
      translated_ability_name = translator.translate(name, from: 'en', to: 'pt')
      desc = ability_data['desc']
      translated_desc = translator.translate(desc, from: 'en', to: 'pt')
      { 'name' => translated_ability_name, 'desc' => translated_desc }
    end

    actions = data['actions'].map do |action_data|
      name = action_data['name']
      translated_action_name = translator.translate(name, from: 'en', to: 'pt')
      desc = action_data['desc']
      translated_action_desc = translator.translate(desc, from: 'en', to: 'pt')
      { 'name' => translated_action_name, 'desc' => translated_action_desc }
    end

    @monster_data = {
      'name' => translated_name,
      'size' => translated_size,
      'type' => translated_type,
      'armor_class' => armor_class,
      'hit_points' => hit_points,
      'proficiencies' => proficiencies,
      'special_abilities' => special_abilities,
      'actions' => actions
    }

    render 'monstros'
  end
end
