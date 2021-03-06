# Encoding: utf-8
#
# Copyright:: Copyright 2015, Google Inc. All Rights Reserved.
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
# Includes a way to iterate over a report stream by line, rather than in
# arbitrary chunks.

module AdwordsApi
  class ReportStream
    def initialize(report_utils, report_definition, cid = nil, format = nil,
        is_awql = false, &block)
      @report_utils = report_utils
      @report_definition = report_definition
      @format = format
      @cid = cid
      @block = block
      @is_awql = is_awql
    end

    def self.set_up(report_utils, report_definition, cid = nil, &block)
      return ReportStream.new(report_utils, report_definition, cid, &block)
    end

    def self.set_up_with_awql(
        report_utils, report_query, format, cid = nil, &block)
      return ReportStream.new(
          report_utils, report_query, cid, format, true, &block)
    end

    def each_line()
      # Determine which method and arguments to use depending on whether
      # this is an AWQL request or not.
      method = 'download_report_as_stream'
      method += '_with_awql' if @is_awql
      args = [@report_definition]
      args << @format if @is_awql
      args << @cid

      leftover_data = ''
      @report_utils.send(method, *args) do |batch|
        data_to_process = leftover_data + batch
        lines = data_to_process.split('\n')
        leftover_data = lines.pop
        lines.each do |line|
          @block.call(line)
        end
      end
      @block.call(leftover_data) unless leftover_data.empty?()
    end
  end
end
