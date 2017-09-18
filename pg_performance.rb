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
		setting :root_url
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


	# monitoring aliveness endpoint
	get '/heartbeat' do
		'alive'
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

	get '/all-active' do
		erb :all_active, :layout => :default, locals: {
				all_active_rows: all_active_rows
		}
	end

	get '/long-running' do
		erb :long_running, :layout => :default, locals: {
				long_running_rows: long_running_rows
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

	def all_active_rows
		all_active_rows_ds = self.activity_stats_dataset
		return all_active_rows_ds.all
	end

	def long_running_rows
		long_running_rows_ds = self.activity_stats_dataset.
				where { query_start < Time.now - 1 }
		return long_running_rows_ds.all
	end

	def activity_stats_dataset
		return PGPerformance.db[:pg_stat_activity].
				where( datname: PGPerformance.target_db ).
				where( state: 'active' ).
				limit( 20 ).
				select { [ application_name, query_start, state, query ] }
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
