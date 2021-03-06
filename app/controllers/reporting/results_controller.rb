module Reporting
  class ResultsController < ApplicationController
    include ReportHelper

    before_action :verify_permission

    def index
      q_param = params[:q]
      page = params[:page]
      @per_page = (params[:per_page] || Kaminari.config.default_per_page).to_i

      @report = Report.find params[:report_id]
      @q = @report.data_model.ransack q_param
      @params = {q: q_param}

      # default order by :id
      if !@report.data_model.columns_hash.keys.index("id").nil? 
        @q.sorts = "id asc" if @q.sorts.empty?
      end

      # total_results is for exporting
      total_results = @q.result

      # filter data based on accessibility
      total_results = filter_data(total_results)

      # list all output fields
      # if output_fields is empty, then export all columns in this table
      if @report.output_fields.blank?
        @fields = @report.data_model.column_names.map{
          |x| {
            name: x 
          }
        }
      else
        @fields = []
        @report.output_fields.order(:sort_order, :id).each do |output_field| 
          alias_name = output_field.alias_name.try(:downcase)
          if alias_name
            total_results = total_results.select(output_field.name + " as " + alias_name)
          else
            total_results = total_results.select(output_field.name)
          end

          if output_field.group_by
            total_results = total_results.group(output_field.name)
          end

          @fields << {
            name: alias_name || output_field.name,
            title: output_field.title
          }
        end

        # make sure primary_key is selected (.find_each requires)
        total_results = total_results.select(@report.primary_key) if !@report.output_fields.pluck(:name).index(@report.primary_key)
      end

      if q_param[:s].present?
        total_results = total_results.order(q_param[:s])
      end

      # @results is for html display; only render current page
      @results = total_results.page(page).per(@per_page)
      # this is used to test if any sql exception is triggered in querying
      # commen errors: table not found
      first_result = @results.limit(1) 

      respond_to do |format|
        format.html
        format.csv do 
          render_csv("#{Time.current.strftime('%Y%m%d%H%M')}_#{@report.name.underscore}.csv", total_results, @fields)
        end
      end

    end

    private

    def verify_permission
      authorize! :access, Report
    end

    def filter_data(results)
      # data access filtering by provider_id
      
      unless current_user.super_admin?
        Reporting::FilterField.includes(:lookup_table)
          .where(filter_group_id: @report.filter_groups.pluck(:id).uniq).each do |field|
          
          is_field_available = !@report.data_model.columns_hash.keys.index(field.name).nil? rescue false
          next if !is_field_available

          data_access_type = field.lookup_table.data_access_type if field.lookup_table
          unless data_access_type.blank? || @report.data_model.columns_hash.keys.index(field.name).nil?
            
            field_name =  "\"#{field.name}\""

            if data_access_type.to_sym == :provider
              results = results.where("#{field_name} = ?" , current_user.try(:current_provider).try(:id))
            end

          end
           
        end
      end

      results
    end

    def render_csv(file_name, data, fields)
      set_file_headers file_name
      set_streaming_headers

      response.status = 200

      #setting the body to an enumerator, rails will iterate this enumerator
      self.response_body = csv_lines(data, fields)
    end


    def set_file_headers(file_name)
      headers["Content-Type"] = "text/csv"
      headers["Content-disposition"] = "attachment; filename=\"#{file_name}\""
    end


    def set_streaming_headers
      #nginx doc: Setting this to "no" will allow unbuffered responses suitable for Comet and HTTP streaming applications
      headers['X-Accel-Buffering'] = 'no'

      headers["Cache-Control"] ||= "no-cache"
      headers.delete("Content-Length")
    end

    def csv_lines(data, fields)

      # Excel is stupid if the first two characters of a csv file are "ID". Necessary to
      # escape it. https://support.microsoft.com/kb/215591/EN-US
      headers = []
      fields.each do |field|
        headers << (field[:title].blank? ? field[:name] : field[:title])
      end

      if headers[0].start_with? "ID"
        headers = Array.new(headers)
        headers[0] = "'" + headers[0]
      end

      # refresh primary_key in case it's changed
      @report.data_model.primary_key = @report.primary_key

      Enumerator.new do |y|
        CSV.generate do |csv|
          y << headers.to_csv

          # find_each would reduce memory usage, but it relies on valid primary_key
          data.find_each do |row|
            y << fields.map { |field|
              format_output row.send(field[:name]), 
                @report.data_model.columns_hash[field[:name].to_s].try(:type),  
                field[:formatter]
            }.to_csv
          end
        end
      end

    end

  end
end
