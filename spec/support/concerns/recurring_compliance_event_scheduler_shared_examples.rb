require 'spec_helper'

# For model specs
RSpec.shared_examples "a recurring compliance event scheduler" do
  describe "occurrence" do
    before do
      # These options reflect the concern setup method
      #   creates_occurrences_for :foo, on: :bar
      
      # Set @occurrence_owner_association in the described class, i.e. :drivers 
      # or :vehicles
      fail "@occurrence_owner_association instance variable required" unless defined? @occurrence_owner_association
      @occurrence_owner_class = @occurrence_owner_association.to_s.singularize.camelize.constantize
      @occurrence_owner_class_factory = @occurrence_owner_class.name.underscore.to_sym

      # Set @occurrence_association in the described class, i.e 
      # :driver_compliances or :vehicle_maintenance_compliances
      fail "@occurrence_association instance variable required" unless defined? @occurrence_association
      @occurrence_class = @occurrence_association.to_s.singularize.camelize.constantize
      @occurrence_class_factory = @occurrence_class.name.underscore.to_sym
      
      # i.e. :recurring_driver_compliance or 
      # :recurring_vehicle_maintenance_compliance
      @recurrence_class = described_class
      @recurrence_class_factory = @recurrence_class.name.underscore.to_sym
      
      @complete = if defined? @complete_with and @complete_with.is_a? Proc
        @complete_with
      else
        Proc.new do |compliance|
          compliance.update_attributes compliance_date: Date.current
        end
      end
    end

    it "creates an association to its occurrences" do
      reflection = @recurrence_class.reflect_on_association(@occurrence_association)
      expect(reflection.macro).to eq :has_many
    end

    it "has an association to its occurrence owners through its provider" do
      reflection = @recurrence_class.reflect_on_association(@occurrence_owner_association)
      expect(reflection.macro).to eq :has_many
      expect(reflection.options[:through]).to eq :provider
    end

    it "can find associated occurrences for a particular owner" do
      recurrence = create @recurrence_class_factory
      owner = create @occurrence_owner_class_factory, provider: recurrence.provider
      @recurrence_class.generate!
      expect(recurrence.occurrences_for_owner(owner)).to match_array owner.send(@occurrence_association)
    end

    it "requires a provider" do
      recurrence = build @recurrence_class_factory, provider: nil
      expect(recurrence.valid?).to be_falsey
      expect(recurrence.errors.keys).to include :provider
    end

    it "requires an event_name" do
      recurrence = build @recurrence_class_factory, event_name: nil
      expect(recurrence.valid?).to be_falsey
      expect(recurrence.errors.keys).to include :event_name
    end

    # The described class may decide this is not a required field, but the
    # values should still be restricted to this list
    it "requires a recurrence_schedule be one of 'days', 'weeks', 'months', or 'years'" do
      recurrence = build @recurrence_class_factory, recurrence_schedule: "foo"
      expect(recurrence.valid?).to be_falsey
      expect(recurrence.errors.keys).to include :recurrence_schedule

      %w(days weeks months years).each do |schedule|
        recurrence.recurrence_schedule = schedule
        expect(recurrence.valid?).to be_truthy
      end
    end

    # The described class may decide this is not a required field, but the
    # values should still be restricted to an integer greater than 0
    it "requires a numeric recurrence_frequency greater than 0" do
      recurrence = build @recurrence_class_factory, recurrence_frequency: nil

      %w(foo -1 0).each do |frequency|
        recurrence.recurrence_frequency = frequency
        expect(recurrence.valid?).to be_falsey
        expect(recurrence.errors.keys).to include :recurrence_frequency
      end

      recurrence.recurrence_frequency = "1"
      expect(recurrence.valid?).to be_truthy
    end

    # The described class may decide this is not a required field, but the
    # values should still be restricted to this list
    it "requires a valid start_date on or after today" do
      recurrence = build @recurrence_class_factory, start_date: nil

      recurrence.start_date = "foo"
      expect(recurrence.valid?).to be_falsey
      expect(recurrence.errors.keys).to include :start_date

      recurrence.start_date = Date.current
      expect(recurrence.valid?).to be_truthy
    end

    it "requires a future_start_rule of either 'immediately', 'on_schedule' (i.e. based on start_date), or 'time_span'" do
      recurrence = build @recurrence_class_factory, future_start_rule: nil, future_start_schedule: "days", future_start_frequency: 1
      expect(recurrence.valid?).to be_falsey
      expect(recurrence.errors.keys).to include :future_start_rule

      recurrence.future_start_rule = "foo"
      expect(recurrence.valid?).to be_falsey
      expect(recurrence.errors.keys).to include :future_start_rule

      %w(immediately on_schedule time_span).each do |rule|
        recurrence.future_start_rule = rule
        expect(recurrence.valid?).to be_truthy
      end
    end

    it "requires a future_start_schedule of either 'days', 'weeks', 'months', or 'years' when future_start_rule is 'time_span'" do
      recurrence = build @recurrence_class_factory, future_start_rule: 'time_span', future_start_schedule: nil, future_start_frequency: 1
      expect(recurrence.valid?).to be_falsey
      expect(recurrence.errors.keys).to include :future_start_schedule

      recurrence.future_start_schedule = "foo"
      expect(recurrence.valid?).to be_falsey
      expect(recurrence.errors.keys).to include :future_start_schedule

      %w(days weeks months years).each do |schedule|
        recurrence.future_start_schedule = schedule
        expect(recurrence.valid?).to be_truthy
      end
    end

    it "requires a numeric future_start_frequency greater than 0 when future_start_rule is 'time_span'" do
      recurrence = build @recurrence_class_factory, future_start_rule: 'time_span', future_start_schedule: 'days', future_start_frequency: nil
      expect(recurrence.valid?).to be_falsey
      expect(recurrence.errors.keys).to include :future_start_frequency

      %w(foo -1 0).each do |frequency|
        recurrence.future_start_frequency = frequency
        expect(recurrence.valid?).to be_falsey
        expect(recurrence.errors.keys).to include :future_start_frequency
      end

      recurrence.future_start_frequency = "1"
      expect(recurrence.valid?).to be_truthy
    end

    it "can prefer compliance based scheduling over frequency based scheduling" do
      recurrence = build @recurrence_class_factory, compliance_based_scheduling: nil
      expect(recurrence.valid?).to be_falsey
      expect(recurrence.errors.keys).to include :compliance_based_scheduling

      [true, false].each do |bool|
        recurrence.compliance_based_scheduling = bool.to_s
        expect(recurrence.valid?).to be_truthy
        expect(recurrence.compliance_based_scheduling?).to eq(bool)
      end
    end

    it "does not automatically generate child compliance events on creation (allowing for a period of time to modify the new event)" do
      expect {
        create @recurrence_class_factory
      }.not_to change(@occurrence_class, :count)
    end
  
    describe "updates" do
      it "only allows the recurrence_notes, event_name, and event_notes fields to be modified once it has spawned children" do
        recurrence = create @recurrence_class_factory, event_name: "My Event", event_notes: nil, recurrence_notes: nil
        create @occurrence_class_factory, @recurrence_class_factory => recurrence

        recurrence.start_date = Date.tomorrow
        expect(recurrence.valid?).to be_falsey
        expect(recurrence.errors.keys).to include :start_date

        recurrence.reload
        recurrence.event_name = "My New Event"
        recurrence.event_notes = "My Event Notes"
        recurrence.recurrence_notes = "My Recurrence Notes"
        expect(recurrence.valid?).to be_truthy
      end

      it "pushes changes to event_name and event_notes fields to children" do
        recurrence = create @recurrence_class_factory, event_name: "My Event", event_notes: nil
        compliance_occurrence = create @occurrence_class_factory, @recurrence_class_factory => recurrence

        expect {
          recurrence.update_attributes event_name: "My Update Event Name", event_notes: "My Updated Event Notes"
        }.to change { [compliance_occurrence.reload.event, compliance_occurrence.reload.notes] }.to(["My Update Event Name", "My Updated Event Notes"])
      end
    end

    describe "#destroy" do
      it "nullifies the association on children when destroyed, by default" do
        recurrence = create @recurrence_class_factory, event_name: "My Event", event_notes: nil
        compliance_occurrence = create @occurrence_class_factory, @recurrence_class_factory => recurrence

        expect {
          recurrence.destroy
        }.to change(@recurrence_class, :count).by(-1)
        expect(compliance_occurrence.reload.send(@recurrence_class_factory)).to be_nil
      end

      it "can optionally delete incomplete children when destroyed, but will still nullify complete children" do
        recurrence = create @recurrence_class_factory, event_name: "My Event", event_notes: nil
        compliance_occurrence_1 = create @occurrence_class_factory, :complete, @recurrence_class_factory => recurrence
        compliance_occurrence_2 = create @occurrence_class_factory, @recurrence_class_factory => recurrence
        compliance_occurrence_3 = create @occurrence_class_factory, :recurring

        expect {
          recurrence.destroy_with_incomplete_children!
        }.to change(@recurrence_class, :count).by(-1)
        expect(compliance_occurrence_1.reload.send(@recurrence_class_factory)).to be_nil
        expect(@occurrence_class.all).to include compliance_occurrence_1
        expect(@occurrence_class.all).not_to include compliance_occurrence_2
        expect(@occurrence_class.all).to include compliance_occurrence_3
      end
    end

    describe ".adjusted_start_date" do
      describe "when as_of is before the recurrence start_date" do
        before do
          # as_of defaults to the current date
          @recurrence = create @recurrence_class_factory,
            start_date: Date.current.tomorrow,
            recurrence_frequency: 1,
            recurrence_schedule: "months"
        end

        describe "with a future_start_rule of 'immediately'" do
          it "should return the start_date" do
            expect(@recurrence_class.adjusted_start_date @recurrence).to eq @recurrence.start_date
          end
        end

        describe "with a future_start_rule of 'on_schedule'" do
          before do
            @recurrence.update_columns future_start_rule: "on_schedule"
          end

          it "should return the start_date" do
            expect(@recurrence_class.adjusted_start_date @recurrence).to eq @recurrence.start_date
          end
        end

        describe "with a future_start_rule of 'time_span'" do
          before do
            @recurrence.update_columns future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 10
          end

          it "should return the start_date" do
            expect(@recurrence_class.adjusted_start_date @recurrence).to eq @recurrence.start_date
          end
        end
      end

      describe "when as_of is after the recurrence start_date" do
        before do
          # Time.now is now frozen at Monday, June 1, 2015
          Timecop.freeze(Date.parse("2015-06-01"))

          @recurrence = create @recurrence_class_factory,
            start_date: Date.current,
            recurrence_frequency: 1,
            recurrence_schedule: "months"
        end

        after do
          Timecop.return
        end

        describe "with a future_start_rule of 'immediately'" do
          it "should return the as_of date" do
            expect(@recurrence_class.adjusted_start_date @recurrence, as_of: Date.current.tomorrow).to eq Date.current.tomorrow
          end
        end

        describe "with a future_start_rule of 'on_schedule'" do
          before do
            @recurrence.update_columns future_start_rule: "on_schedule"
          end

          it "should return the next date of the occurrence on or after as_of, according to the recurrence schedule" do
            expect(@recurrence_class.adjusted_start_date @recurrence, as_of: Date.current.tomorrow).to eq Date.parse("2015-07-01")
          end
        end

        describe "with a future_start_rule of 'time_span'" do
          before do
            @recurrence.update_columns future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 10
          end

          it "should return the next date of the occurrence starting after the time span from as_of" do
            expect(@recurrence_class.adjusted_start_date @recurrence, as_of: Date.parse("2015-06-15")).to eq Date.parse("2015-06-25")
          end
        end
      end
    end

    describe ".occurrence_dates_on_schedule_in_range" do
      before do
        # Time.now is now frozen at Thursday, January 1, 2015
        Timecop.freeze(Date.parse("2015-01-01"))

        @recurrence = create @recurrence_class_factory,
          start_date: Date.current,
          recurrence_frequency: 1,
          recurrence_schedule: "months"
      end

      after do
        Timecop.return
      end

      it "uses the recurrence start_date to calculate the first occurrence by default" do
        expect(@recurrence_class.occurrence_dates_on_schedule_in_range(@recurrence).first).to eq @recurrence.start_date
      end

      it "accepts an optional first_date to calculate the first occurrence" do
        expect(@recurrence_class.occurrence_dates_on_schedule_in_range(@recurrence, first_date: @recurrence.start_date.tomorrow).first).to eq @recurrence.start_date.tomorrow
      end

      it "calculates dates within a 6 month window by default" do
        expect(@recurrence_class.occurrence_dates_on_schedule_in_range(@recurrence).last).to eq Date.parse("2015-06-01")
      end

      it "can accept an optional range_start_date" do
        expect(@recurrence_class.occurrence_dates_on_schedule_in_range(@recurrence, range_start_date: Date.current.tomorrow).first).to eq Date.parse("2015-02-01")
      end

      it "can accept an optional range_end_date" do
        expect(@recurrence_class.occurrence_dates_on_schedule_in_range(@recurrence, range_end_date: Date.current.tomorrow).last).to eq Date.parse("2015-01-01")
      end

      it "setting a range_start_date influences the default range_end_date" do
        expect(@recurrence_class.occurrence_dates_on_schedule_in_range(@recurrence, range_start_date: Date.parse("2015-07-01")).last).to eq Date.parse("2015-12-01")
      end

      # Add examples as edge-cases are discovered
      describe "irregular traversals" do
        # Jan 31 + 1.month is Feb 28, and Feb 28 + 1.month = Mar 28
        # But Jan 31 + 2.months = Mar 31
        describe "handles monthly recurrences when the first_date is on the 31st" do
          before do
            @recurrence = create @recurrence_class_factory,
              start_date: Date.parse("2015-01-31"),
              recurrence_frequency: 1,
              recurrence_schedule: "months"
          end

          it "properly finds the last day of each subsequent month, even when the range_start_date is far into the future" do
            expect(@recurrence_class.occurrence_dates_on_schedule_in_range @recurrence, range_start_date: Date.parse("2023-09-15"), range_end_date: Date.parse("2024-09-14")).to eq [
              Date.parse("2023-09-30"),
              Date.parse("2023-10-31"),
              Date.parse("2023-11-30"),
              Date.parse("2023-12-31"),
              Date.parse("2024-01-31"),
              Date.parse("2024-02-29"),
              Date.parse("2024-03-31"),
              Date.parse("2024-04-30"),
              Date.parse("2024-05-31"),
              Date.parse("2024-06-30"),
              Date.parse("2024-07-31"),
              Date.parse("2024-08-31"),
            ]
          end
        end
      end
    end

    describe ".next_occurrence_date_from_previous_date_in_range" do
      before do
        # Time.now is now frozen at Thursday, January 1, 2015
        Timecop.freeze(Date.parse("2015-01-01"))

        @recurrence = create @recurrence_class_factory,
          start_date: Date.current,
          recurrence_frequency: 1,
          recurrence_schedule: "months"
      end

      after do
        Timecop.return
      end

      it "returns the next occurrence date from previous_date" do
        expect(@recurrence_class.next_occurrence_date_from_previous_date_in_range @recurrence, Date.parse("2015-01-01")).to eq Date.parse("2015-02-01")
      end

      it "calculates dates within a 6 month window by default" do
        @recurrence.update_columns recurrence_schedule: "years"
        expect(@recurrence_class.next_occurrence_date_from_previous_date_in_range @recurrence, Date.parse("2015-01-01")).to be_nil
      end

      it "can accept an optional range_end_date" do
        @recurrence.update_columns recurrence_schedule: "years"
        expect(@recurrence_class.next_occurrence_date_from_previous_date_in_range @recurrence, Date.parse("2015-01-01"), range_end_date: Date.parse("2016-01-01")).to eq Date.parse("2016-01-01")
      end

      it "doesn't care if we're super far into the future" do
        Timecop.freeze(Date.parse("2099-01-01")) do
          expect(@recurrence_class.next_occurrence_date_from_previous_date_in_range @recurrence, Date.parse("2015-01-01")).to eq Date.parse("2015-02-01")
          expect(@recurrence_class.next_occurrence_date_from_previous_date_in_range @recurrence, Date.current).to eq Date.parse("2099-02-01")
        end
      end

      # Add examples as edge-cases are discovered
      describe "irregular traversals" do
        # Jan 31 + 1.month is Feb 28, and Feb 28 + 1.month = Mar 28
        # But Jan 31 + 2.months = Mar 31
        # However we're only dealing with one unit at a time, so we don't care
        describe "handles monthly recurrences when the first_date is on the 31st" do
          before do
            @recurrence = create @recurrence_class_factory,
              start_date: Date.parse("2015-01-31"),
              recurrence_frequency: 1,
              recurrence_schedule: "months",
              compliance_based_scheduling: true
          end

          it "ignores irregular monthly traversals, because the next due date is based solely off of the previous compliance date" do
            expect(@recurrence_class.next_occurrence_date_from_previous_date_in_range @recurrence, Date.parse("2015-01-31")).to eq Date.parse("2015-02-28")
            expect(@recurrence_class.next_occurrence_date_from_previous_date_in_range @recurrence, Date.parse("2015-02-28")).to eq Date.parse("2015-03-28")
            expect(@recurrence_class.next_occurrence_date_from_previous_date_in_range @recurrence, Date.parse("2015-03-31")).to eq Date.parse("2015-04-30")
          end
        end
      end
    end

    describe ".generate!" do
      before do
        # Time.now is now frozen at Monday, June 1, 2015
        Timecop.freeze(Date.parse("2015-06-01"))

        # Start date is Tuesday, June 2, 2015
        @recurrence = create @recurrence_class_factory,
          recurrence_frequency: 2,
          recurrence_schedule: "weeks",
          start_date: Date.parse("2015-06-02"),
          future_start_rule: "immediately",
          compliance_based_scheduling: false

        @provider = @recurrence.provider
      end

      after do
        Timecop.return
      end

      describe "sanity check" do
        before do
          @owner = create @occurrence_owner_class_factory, provider: @provider
        end

        it "generates child compliance events for occurrence owners of providers with recurrences defined" do
          expect {
            @recurrence_class.generate!
          }.to change { @owner.send(@occurrence_association).count }
        end

        it "doesn't generates child compliance events for occurrence owners of providers without recurrences defined" do
          owner_2 = create @occurrence_owner_class_factory
          expect {
            @recurrence_class.generate!
          }.not_to change { owner_2.send(@occurrence_association).count }
        end

        it "sets the name and notes of generated children to the recurrence's event_name and event_notes fields, respectively" do
          @recurrence_class.generate!
          expect(@owner.send(@occurrence_association).first.event).to eq @recurrence.event_name
          expect(@owner.send(@occurrence_association).first.notes).to eq @recurrence.event_notes
        end

        it "is idempotent" do
          @recurrence_class.generate!
          expect {
            @recurrence_class.generate!
          }.not_to change(@occurrence_class, :count)
        end
      end

      # Frequency based scheduling is used when a compliance must be completed on
      # a regular schedule, regardless of when the previous occurrences were
      # completed.
      describe "when frequency based scheduling is preferred" do
        describe "for owners that already exist when the recurrence is created" do
          before do
            @owner = create @occurrence_owner_class_factory, provider: @provider
          end

          describe "without prior event occurrences" do
            it "schedules new events on a schedule based on the start_date, up to 6 months out" do
              # Time is still frozen at Monday, June 1, 2015
              # Starting from Tue, Jun 2, 2015, bi-weekly occurrences over
              # the next 6 months should include:
              expected_dates = [
                "2015-06-02", "2015-06-16", "2015-06-30",
                "2015-07-14", "2015-07-28",
                "2015-08-11", "2015-08-25",
                "2015-09-08", "2015-09-22",
                "2015-10-06", "2015-10-20",
                "2015-11-03", "2015-11-17"
              ]

              expect {
                @recurrence_class.generate!
              }.to change(@occurrence_class, :count).by(13)

              expected_dates.each do |expected_date|
                expect(@owner.send(@occurrence_association).where(due_date: expected_date)).to exist
              end
            end

            it "won't schedule anything when the start_date is more than 6 months away" do
              @recurrence.update_columns start_date: 7.months.from_now
              expect {
                @recurrence_class.generate!
              }.not_to change(@occurrence_class, :count)
            end

            it "will only schedule one event when the recurrence frequency is is greater than 6 months" do
              @recurrence.update_columns recurrence_frequency: 7, recurrence_schedule: "months"
              expect {
                @recurrence_class.generate!
              }.to change(@occurrence_class, :count).by(1)
            end

            it "will only schedule one event when the start_date means the second occurrence will fall outside of 6 months" do
              @recurrence.update_columns start_date: 3.months.from_now, recurrence_frequency: 4, recurrence_schedule: "months"
              expect {
                @recurrence_class.generate!
              }.to change(@occurrence_class, :count).by(1)
            end
          end

          describe "with prior event occurrences" do
            before do
              # Time is still frozen at Monday, June 1, 2015
              # Creates 13 bi-weekly occurrences due from 2015-06-02 to 2015-11-17
              @recurrence_class.generate!
            end

            it "schedules new events on a schedule based on the due date" do
              # Travel 1 week into the future, to June 8, 2015
              Timecop.freeze(Date.parse("2015-06-08")) do
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(1)

                # It should add 1 new bi-monthly occurrences due on 2015-12-01
                expect(@owner.send(@occurrence_association).last.due_date).to eq Date.parse("2015-12-01")
              end
            end
          end
        end

        describe "for owners created after the recurrence is created" do
          before do
            # Time is still frozen at Monday, June 1, 2015
            # Creates 13 bi-weekly occurrences due from 2015-06-02 to 2015-11-17
            @recurrence_class.generate!
          end

          describe "when it is still before the recurrence start_date" do
            before do
              # Time is still frozen at Monday, June 1, 2015
              @owner = create @occurrence_owner_class_factory, provider: @provider
            end
    
            describe "with a future_start_rule of 'immediately'" do
              it "should generate new events on schedule, starting with the recurrence start_date" do
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(13)

                expect(@owner.send(@occurrence_association).first.due_date).to eq @recurrence.start_date
                expect(@owner.send(@occurrence_association).last.due_date).to eq Date.parse("2015-11-17")
              end
            end

            describe "with a future_start_rule of 'on_schedule'" do
              before do
                @recurrence.update_columns future_start_rule: "on_schedule"
              end
      
              it "should generate new events on schedule, starting with the recurrence start_date" do
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(13)

                expect(@owner.send(@occurrence_association).first.due_date).to eq @recurrence.start_date
                expect(@owner.send(@occurrence_association).last.due_date).to eq Date.parse("2015-11-17")
              end
            end

            describe "with a future_start_rule of 'time_span'" do
              before do
                @recurrence.update_columns future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 10
              end
      
              it "should generate new events on schedule, starting with the recurrence start_date" do
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(13)

                expect(@owner.send(@occurrence_association).first.due_date).to eq @recurrence.start_date
                expect(@owner.send(@occurrence_association).last.due_date).to eq Date.parse("2015-11-17")
              end
            end
          end

          describe "when it is after the recurrence start_date" do
            before do
              # Travel 1 week into the future, to June 8, 2015
              Timecop.freeze(Date.parse("2015-06-08"))

              @owner = create @occurrence_owner_class_factory, provider: @provider
            end
    
            after do
              Timecop.return
            end
    
            describe "with a future_start_rule of 'immediately'" do
              it "should generate new events on schedule, starting immediately" do
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(14)

                expect(@owner.send(@occurrence_association).first.due_date).to eq Date.parse("2015-06-08")
                expect(@owner.send(@occurrence_association).last.due_date).to eq Date.parse("2015-12-07")
              end
            end

            describe "with a future_start_rule of 'on_schedule'" do
              before do
                @recurrence.update_columns future_start_rule: "on_schedule"
              end
      
              it "should generate new events on schedule, starting with the next occurrence from today" do            
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(13)

                expect(@owner.send(@occurrence_association).first.due_date).to eq Date.parse("2015-06-16")
                expect(@owner.send(@occurrence_association).last.due_date).to eq Date.parse("2015-12-01")
              end
            end

            describe "with a future_start_rule of 'time_span'" do
              before do
                @recurrence.update_columns future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 10
              end
      
              it "should generate new events on schedule, with the first occurrence starting after the time span from today" do
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(13)

                expect(@owner.send(@occurrence_association).first.due_date).to eq Date.parse("2015-06-18")
                expect(@owner.send(@occurrence_association).last.due_date).to eq Date.parse("2015-12-03")
              end
            end
          end
        end
      end

      # Compliance based scheduling is used when a compliance is good for a
      # specific period of time. An example would be CPR certification, where the
      # certificate is only good for 1 year after the last time you completed
      # certification. For instance, if you completed certification on June 1,
      # 2015 it would be Good until May 30, 2016. If you then completed the
      # recertification on May 15, 2016, your new certificate would be good until
      # May 14, 2017.
      describe "when compliance based scheduling is preferred" do
        before do
          @recurrence.update_columns compliance_based_scheduling: true
        end

        describe "for owners that already exist when the recurrence is created" do
          before do
            @owner = create @occurrence_owner_class_factory, provider: @provider
          end

          describe "without prior event occurrences" do
            it "schedules only one event on the start_date (no previous occurrences exists that could be completed)" do
              expect {
                @recurrence_class.generate!
              }.to change(@occurrence_class, :count).by(1)

              expect(@occurrence_class.last.due_date).to eq @recurrence.start_date
            end
          end

          describe "with prior event occurrences" do
            before do
              # Time is still frozen at Monday, June 1, 2015
              # Creates 1 occurrence due on 2015-06-02
              @recurrence_class.generate!
            end

            describe "when the previous occurrence is still incomplete" do
              it "schedules no new events" do
                # Travel 2 weeks into the future, to June 15, 2015
                Timecop.freeze(2.weeks.from_now) do
                  expect {
                    @recurrence_class.generate!
                  }.not_to change(@occurrence_class, :count)
                end
              end
            end

            describe "when the previous occurrence is complete" do
              before do
                # Time is still frozen at Monday, June 1, 2015
                @complete.call @owner.send(@occurrence_association).last
              end

              it "schedules 1 new event" do
                # Travel 2 weeks into the future, to June 15, 2015
                Timecop.freeze(2.weeks.from_now) do
                  expect {
                    @recurrence_class.generate!
                  }.to change(@occurrence_class, :count).by(1)

                  # Last occurrence was due 2015-06-02, completed 2015-06-01
                  # It should add 1 new occurrence due on 2015-06-15
                  expect(@owner.send(@occurrence_association).last.due_date).to eq Date.parse("2015-06-15")
                end
              end
            end
          end
        end

        describe "for owners created after the recurrence is created" do
          before do
            # Time is still frozen at Monday, June 1, 2015
            # Creates 13 bi-weekly occurrences due from 2015-06-02 to 2015-11-17
            @recurrence_class.generate!
          end

          describe "when it is still before the recurrence start_date" do
            before do
              # Time is still frozen at Monday, June 1, 2015
              @owner = create @occurrence_owner_class_factory, provider: @provider
            end
    
            describe "with a future_start_rule of 'immediately'" do
              it "should generate the 1st event on the recurrence start_date" do
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(1)

                expect(@occurrence_class.last.due_date).to eq @recurrence.start_date
              end
            end

            describe "with a future_start_rule of 'on_schedule'" do
              before do
                @recurrence.update_columns future_start_rule: "on_schedule"
              end
      
              it "should generate the 1st event on the recurrence start_date" do
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(1)

                expect(@occurrence_class.last.due_date).to eq @recurrence.start_date
              end
            end

            describe "with a future_start_rule of 'time_span'" do
              before do
                @recurrence.update_columns future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 10
              end
      
              it "should generate the 1st event on the recurrence start_date" do
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(1)

                expect(@occurrence_class.last.due_date).to eq @recurrence.start_date
              end
            end
          end

          describe "when it is after the recurrence start_date" do
            before do
              # Travel 1 week into the future, to June 8, 2015
              Timecop.freeze(Date.parse("2015-06-08"))

              @owner = create @occurrence_owner_class_factory, provider: @provider
            end
    
            after do
              Timecop.return
            end
    
            describe "with a future_start_rule of 'immediately'" do
              it "should generate one new event, starting immediately" do
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(1)

                expect(@owner.send(@occurrence_association).last.due_date).to eq Date.parse("2015-06-08")
              end
            end

            describe "with a future_start_rule of 'on_schedule'" do
              before do
                @recurrence.update_columns future_start_rule: "on_schedule"
              end
      
              it "should generate one new event, starting with the next occurrence from today" do
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(1)

                expect(@owner.send(@occurrence_association).last.due_date).to eq Date.parse("2015-06-16")
              end
            end

            describe "with a future_start_rule of 'time_span'" do
              before do
                @recurrence.update_columns future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 10
              end
      
              it "should generate one new event starting after the time span from today" do
                expect {
                  @recurrence_class.generate!
                }.to change(@occurrence_class, :count).by(1)

                expect(@owner.send(@occurrence_association).last.due_date).to eq Date.parse("2015-06-18")
              end
            end
          end
        end
      end
    end
  end
end
