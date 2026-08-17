# frozen_string_literal: true

class AllowNullContextOnPreferences < ActiveRecord::Migration[8.0]
  def up
    change_column_null :preferences, :context_host, true
    change_column_null :preferences, :context_association, true
    change_column_default :preferences, :context_host, from: "", to: nil
    change_column_default :preferences, :context_association, from: "", to: nil

    execute <<~SQL
      UPDATE preferences SET context_host = NULL WHERE context_host = '';
      UPDATE preferences SET context_association = NULL WHERE context_association = '';
    SQL
  end

  def down
    execute <<~SQL
      UPDATE preferences SET context_host = '' WHERE context_host IS NULL;
      UPDATE preferences SET context_association = '' WHERE context_association IS NULL;
    SQL

    change_column_default :preferences, :context_host, from: nil, to: ""
    change_column_default :preferences, :context_association, from: nil, to: ""
    change_column_null :preferences, :context_host, false
    change_column_null :preferences, :context_association, false
  end
end
