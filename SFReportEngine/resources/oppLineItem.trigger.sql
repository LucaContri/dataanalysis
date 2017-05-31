use salesforce;
create trigger oppLineItemUpdate 
	before insert on salesforce.opportunity
for each row 
	begin
		update salesforce.opportunitylineitem oli set oli.IsDeleted = 0 where oli.OpportunityId = new.id;
        update salesforce.sf_tables sft set sft.LastSyncDate = least(sft.LastSyncDate, new.LastModifiedDate) where sft.TableName = 'OpportnityLineItem' and sft.Id=320;
	end;

