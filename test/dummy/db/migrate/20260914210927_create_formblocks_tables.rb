# frozen_string_literal: true

# What `bin/rails generate formblocks:install` writes into a host, generated
# from lib/generators/formblocks/install/templates/create_formblocks_tables.rb.tt.
# Keep the two in step.
class CreateFormblocksTables < ActiveRecord::Migration[8.1]
  def change
    create_table :formblocks_settings do |t|
      t.string :tenant # opaque per-tenant key; nil = single global collection
      t.string :primary_color
      t.string :button_text_color

      t.timestamps
    end
    add_index :formblocks_settings, :tenant, unique: true

    create_table :formblocks_forms do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.datetime :published_at
      t.string :primary_color
      t.string :button_text_color
      t.string :tenant
      t.integer :responses_count, null: false, default: 0

      t.timestamps
    end
    add_index :formblocks_forms, :slug, unique: true
    add_index :formblocks_forms, :tenant

    create_table :formblocks_pages do |t|
      t.references :form, null: false, foreign_key: { to_table: :formblocks_forms }
      t.string :kind, null: false, default: 'step'
      t.integer :position, null: false, default: 0
      t.string :button_text

      t.timestamps
    end

    create_table :formblocks_blocks do |t|
      t.references :page, null: false, foreign_key: { to_table: :formblocks_pages }
      t.string :type, null: false
      t.integer :position, null: false, default: 0
      t.string :key
      t.string :label
      t.string :placeholder
      t.text :help_text
      t.text :content
      t.boolean :required, null: false, default: false
      t.json :options
      t.json :settings

      t.timestamps
    end

    create_table :formblocks_responses do |t|
      t.references :form, null: false, foreign_key: { to_table: :formblocks_forms }
      t.string :tenant
      t.json :answers
      t.string :page_url
      t.string :user_agent
      t.string :locale

      t.timestamps
    end
    add_index :formblocks_responses, %i[tenant created_at]
  end
end
