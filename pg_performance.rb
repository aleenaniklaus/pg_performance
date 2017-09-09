require 'sinatra/base'
require 'sinatra/reloader'
require 'sequel'
require 'pg'
require 'rouge'
require 'erb'
require 'configurability'



class PGPerformance < Sinatra::Base
	extend Configurability

	configurability( :pgperformance ) do
		setting :db_uri
		setting :target_db
	end

	def self::db
		return @db ||= Sequel.connect( self.db_uri )
	end


	Sinatra::Base.configure do
		register Sinatra::Reloader
		config_file = File.join(File.dirname(__FILE__), 'config.yml')
		config = Configurability::Config.load( config_file )
		Configurability.configure_objects( config )
	end

	get '/' do
		erb :index, :layout => :default, locals: {
			mean_time_rows: mean_time_rows
		}
	end

	get '/total-time' do
		erb :total_time, :layout => :default, locals: {
			total_time_rows: total_time_rows
		}
	end

	get '/most-frequent' do
		erb :most_frequent, :layout => :default, locals: {
				most_frequent_rows: most_frequent_rows
		}
	end

	helpers do

		def sql(sql)
			formatter = Rouge::Formatters::HTMLInline.new( 'github' )
			lexer = Rouge::Lexers::SQL.new
			return formatter.format(lexer.lex(sql))
		end

	end

	def total_time_rows
		total_time_ds = self.relevant_stats_dataset.
			order_by { total_time.desc }.
			limit( 20 ).
			select { [calls, total_time, mean_time, stddev_time, query] }
		return total_time_ds.all
	end

	def mean_time_rows
		mean_time_ds = self.relevant_stats_dataset.
			order_by { mean_time.desc }.
			limit( 20 ).
			select { [ mean_time, total_time, stddev_time, query] }
		return mean_time_ds.all
	end

	def most_frequent_rows
		most_frequent_rows_ds = self.relevant_stats_dataset.
			order_by { calls.desc }.
			limit( 20 ).
			select { [calls, mean_time, total_time, stddev_time, query] }
		return most_frequent_rows_ds.all
	end

	def relevant_stats_dataset
		return PGPerformance.db[:pg_stat_statements].join( :pg_database, oid: :dbid ).
				where( datname: PGPerformance.target_db ).
				exclude(query: '<insufficient privilege>').
				exclude(query: 'COMMIT').
				exclude(query: 'BEGIN').
				exclude { query.like('%"pg_%') }
	end

end