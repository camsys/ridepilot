require "rails_helper"

RSpec.describe "Lookup Tables" do
  context "for admin" do
    before :each do 
      @admin = create(:admin)
      visit new_user_session_path
      fill_in 'Email', :with => @admin.email
      fill_in 'Password', :with => @admin.password
      click_button 'Log In'
    end

    describe "GET /lookup_tables" do
      it "can see index page with empty dropdown when no lookup tables" do 
        click_link 'Lookup Tables'
        expect(page).to have_select('lookupTableList', options: [])
      end

      it "can see index page with selected dropdown when lookup tables are configured" do 
        @table = create(:lookup_table)
        click_link 'Lookup Tables'
        expect(page).to have_select('lookupTableList', selected: @table.caption, options: [@table.caption])
      end
    end

    describe "GET /lookup_tables/:id" do
      context "display data source values" do 
        before do
          sample_purpose_1 = create(:trip_purpose, name: 'Sample Purpose 1')
          sample_purpose_2 = create(:trip_purpose, name: 'Sample Purpose 2')
          @table = create(:lookup_table) 
          visit lookup_table_path(:id => @table.id)
        end
        it "can see #lookupTable table" do 
          expect(page).to have_table('lookupTable')
        end

        it "can see the full list of values in #lookupTable table" do 
          expect(page.all('table#lookupTable tr').count).to eq(2)
        end
      end

      context "with full permissions to edit lookup table" do
        before do
          sample_purpose_1 = create(:trip_purpose, name: 'Sample Purpose')
          @table = create(:lookup_table) 
          visit lookup_table_path(:id => @table.id)
        end

        it "can see Add Value button" do 
          expect(page).to have_button('addLookupTableValue')
        end

        it "adds a new value to data source" do 
          within '#addLookupTableValueDialog' do 
            fill_in 'value', with: 'New Purpose'
            click_button 'OK'
          end
          
          expect(page).to have_css('#lookupTable tr', text: 'New Purpose')
        end

        context "Edit Value button visibility" do
          it "can initially see disabled Edit Value button" do
            expect(page).to have_css('#editLookupTableValue:disabled')
          end

          skip "can see enabled Edit Value button after selecting a row", js: true do
            within '#lookupTable' do 
              find('tbody tr:first-child').click
            end
            
            expect(page).to have_button('editLookupTableValue')
          end
        end

        skip "edits an exiting value", js: true do 
          within '#lookupTable' do 
            find('tbody tr:first-child').click
          end

          click_button 'editLookupTableValue'
          
          within '#editLookupTableValueDialog' do 
            fill_in 'value', with: 'Updated Purpose'
            click_button 'OK'
          end
          
          expect(page).to have_css('#lookupTable tr', text: 'Updated Purpose')
        end

        context "Delete Value button visibility" do
          it "can initially see disabled Delete Value button" do 
            expect(page).to have_css('#deleteLookupTableValue:disabled')
          end

          skip "can see enabled Delete Value button after selecting a row", js: true do
            within '#lookupTable' do 
              find('tbody tr:first-child').click
            end
            
            expect(page).to have_button('deleteLookupTableValue')
          end
        end

        skip "deletes an exiting value", js: true do 
          within '#lookupTable' do 
            find('tbody tr:first-child').click
          end

          click_button 'deleteLookupTableValue'

          within '#deleteLookupTableValueDialog' do 
            click_button 'OK'
          end
          
          expect(page).to_not have_css('#lookupTable tr', text: 'Sample Purpose')
        end
      end

      context "with no permissions to edit lookup table" do
        before do
          sample_purpose_1 = create(:trip_purpose, name: 'Sample Purpose 1')
          sample_purpose_2 = create(:trip_purpose, name: 'Sample Purpose 2')
          @table = create(:lookup_table, add_value_allowed: false, edit_value_allowed: false, delete_value_allowed: false) 
          visit lookup_table_path(:id => @table.id)
        end

        it "cannot see Add Value button" do 
          expect(page).to have_no_button('addLookupTableValue')
        end

        it "cannot see Edit Value button" do
          expect(page).to have_no_button('editLookupTableValue')
        end

        it "cannot see Delete Value button" do 
          expect(page).to have_no_button('deleteLookupTableValue')
        end
      end
    end

  end
end