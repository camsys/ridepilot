module Reporting
  class ReportsController < ApplicationController
    include ReportHelper

    before_action :verify_permission

    def index
      @reports = all_report_infos
      if !@reports.blank?
        first_report = @reports.first
        @is_generic_report = first_report[:is_generic]
        if @is_generic_report
          redirect_to report_path Report.find(first_report[:id])
        else
          redirect_to main_app.custom_report_path CustomReport.find(first_report[:id])
        end
      end
      
    end

    def show
      @reports = all_report_infos
      @report = Report.find(params[:id])

      # reset column information
      @report.data_model.reset_column_information

      # find out filter_groups
      @filter_groups = @report.specific_filter_groups.order(:sort_order)
    end

    private

    def verify_permission
      authorize! :access, Report
    end
    
  end
end
