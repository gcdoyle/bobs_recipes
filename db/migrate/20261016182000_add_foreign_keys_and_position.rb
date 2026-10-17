class AddForeignKeysAndPosition < ActiveRecord::Migration[6.1]
  JOINS = {
    recipe_ingredients: { recipe_id: :recipes, ingredient_id: :ingredients },
    recipe_categories:  { recipe_id: :recipes, category_id: :categories }
  }.freeze

  def up
    # 1. Remove orphaned join rows (null ids or pointing at deleted records),
    #    otherwise the foreign keys can't be added.
    JOINS.each do |table, columns|
      columns.each do |column, parent|
        removed = delete(<<~SQL)
          DELETE FROM #{table}
          WHERE #{column} IS NULL
             OR NOT EXISTS (SELECT 1 FROM #{parent} WHERE #{parent}.id = #{table}.#{column})
        SQL
        say "removed #{removed} orphaned #{table} rows (#{column})" if removed.to_i > 0
      end
    end

    # 2. Match the bigint primary keys, require the ids, add foreign keys.
    JOINS.each do |table, columns|
      columns.each do |column, parent|
        change_column table, column, :bigint
        change_column_null table, column, false
        add_foreign_key table, parent, column: column
      end
    end

    # 3. Ingredient order within a recipe, backfilled in entry (id) order.
    add_column :recipe_ingredients, :position, :integer
    execute <<~SQL
      UPDATE recipe_ingredients ri
      SET position = numbered.rn
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY recipe_id ORDER BY id) AS rn
        FROM recipe_ingredients
      ) numbered
      WHERE numbered.id = ri.id
    SQL
    add_index :recipe_ingredients, [:recipe_id, :position]
  end

  def down
    remove_index :recipe_ingredients, [:recipe_id, :position]
    remove_column :recipe_ingredients, :position

    JOINS.each do |table, columns|
      columns.each do |column, parent|
        remove_foreign_key table, column: column
        change_column_null table, column, true
        change_column table, column, :integer
      end
    end
    # Deleted orphan rows are not restored.
  end
end
