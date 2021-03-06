class BscMetricsController < ApplicationController
	before_filter :find_project_by_project_id, :authorize
	before_filter :load_metrics
	before_filter :load_currency

	menu_item :bsc
	helper :bsc

	def load_metrics
		@metrics ||= BSC::Metrics.new(@project, Date.today)
	end

	def load_currency
		if params[:currency].present?
			@currency = BSC::Integration.get_currency(params[:currency])
		else
			@currency = BSC::Integration.get_prefered_currency
		end
	end

	def index
		@metric_options = ['mc', 'effort', 'income_expenses', 'deliverables', 'time_entries']
		@currencies = BSC::Integration.get_currencies

		load_headers
		change_metric
	end

	def load_headers
		@metric_options.each do |metric_option|
			case metric_option
			when 'mc'
				@mc_header = BscMc.get_header(@project)
			when 'effort'
				@effort_header = BscEffort.get_header(@project)
			when 'income_expenses'
				@income_expenses_header = BscIncomeExpense.get_header(@project)
			when 'deliverables'
				@deliverables_header = BscDeliverable.get_header(@project)
			when 'time_entries'
				@time_entries_header = BscTimeEntry.get_header(@project)
			end
		end
	end

	def change_metric
		@metric_selected = params[:type] || @metric_options.first
		case @metric_selected
		when 'mc'
			@mc_header ||= BscMc.get_header(@project)
			data = BscMc.get_data(@project.id, Date.today)
			@table_data = data[:chart]
			@chart_data = data[:chart].reverse.to_json
			@scheduled_margin = data[:scheduled_margin]
			@target_margin = data[:target_margin]
			@incomes_trackers = BSC::Integration.get_income_trackers
			@expenses_trackers = BSC::Integration.get_expense_trackers
		when 'effort'
			@effort_header ||= BscEffort.get_header(@project)
			data = BscEffort.get_data(@project.id, Date.today)
			@chart_data = data[:chart].reverse
			@table_data = data[:table]
			@scheduled_finish_date = data[:scheduled_finish_date]
		when 'income_expenses'
			@income_expenses_header ||= BscIncomeExpense.get_header(@project)
			data = BscIncomeExpense.get_data(@project.id)
			@income_table = data[:incomes]
			@expense_table = data[:expenses]
			@calendar_data = data[:calendar]
		when 'deliverables'
			@deliverables_header ||= BscDeliverable.get_header(@project)
			data = BscDeliverable.get_data(@project.id)
			@deliverables_table = data[:deliverables]
			@calendar_data = data[:calendar]
		when 'time_entries'
			@time_entries_header ||= BscTimeEntry.get_header(@project)
			data = BscTimeEntry.get_data(@project.id)
			@table_members = data[:members]
			@table_profiles = data[:profiles]
			@profile_names = data[:profile_names]
		end

		if request.xhr?
          render :json => { :filter => render_to_string(:partial => 'bsc_metrics/metrics/'+@metric_selected, :layout => false) }
        end
	end
end

