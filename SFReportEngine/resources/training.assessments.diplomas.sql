select count(*) from training.certificate__c;

select cont.Name, a.Contact__c, a.Attendee_ID__c, a.Assessor__c , cont.Name, a.Id, a.Name, a.Assessment_Title__c, ct.Id, ct.Name, a.Certificate_Template__c, ac.Id, ac.Name, c.Id, c.Name, certType.Id, certType.Name
from training.assessment__c a 
left join training.certificate_type__c ct on ct.Id = a.Assessment_Title__c
left join training.assessment_competency__c ac on ac.Assessment__c = a.Id
left join training.competency__c c on ac.Competency_Name__c = c.Id
left join training.certificate_type__c certType on certType.Id = a.Assessment_Title__c
left join training.contact cont on cont.Id = a.Contact__c
#left join training.registration__c r on r.Id = a.Attendee_ID__c
#left join training.contact cont on cont.Id = r.Attendee__c
where 
#a.id = 'a0b200000044ZVdAAM'; 
c.Competency_Code__c  = 'research compliance requirements & issues' and a.Contact__c is null;
#cont.Id='0032000000QUonpAAD';

select a.Contact__c, a.Id, a.Name from training.assessment__c a 
where a.Name = 'BSB60407 Advanced Diploma of Management' and a.Contact__c is not null and  a.Assessment_Status__c = 'Competent';

select * from training.assessment__c where RecordTypeId='012200000001LqVAAU';

select count(*) from training.contact;

select cont.Id, cont.Name, r.Id, r.Name, a.Id, a.Name 
from training.contact cont 
left join training.registration__c r on r.Attendee__c = cont.Id
left join training.assessment__c a on r.Id = a.Attendee_ID__c
where cont.Id='0032000000QUonpAAD';

select * from (
select cont.Id, cont.Name, count(ac.Id) as 'Count'
from training.assessment_competency__c ac
inner join training.competency__c c on c.Id = ac.Competency_Name__c
inner join training.assessment__c a on ac.Assessment__c = a.Id
inner join training.registration__c r on r.Id = a.Attendee_ID__c
inner join training.contact cont on cont.Id = r.Attendee__c
where c.Name in('BSBCOM501B','BSBINN601A','BSBMGT605B','BSBMGT616A','BSBOHS604B','BSBOHS605B','BSBOHS607B','BSBRSK501A')
and a.Assessment_Status__c = 'Competent'
group by cont.Id) t where t.Count >=8 limit 100000;


select cont.Id, cont.Name, group_concat(distinct c.Name ORDER BY c.Name DESC SEPARATOR ',')
from training.assessment_competency__c ac
inner join training.competency__c c on c.Id = ac.Competency_Name__c
inner join training.assessment__c a on ac.Assessment__c = a.Id
inner join training.registration__c r on r.Id = a.Attendee_ID__c
inner join training.contact cont on cont.Id = r.Attendee__c
where a.Assessment_Status__c = 'Competent'
group by cont.Id
limit 100000;

select c.Id, c.Name, c.Competency_Name__c, c.Competency_Code__c from training.Competency__c c;

# courses to competencies
select course.Id, course.Name, group_concat(distinct c.Competency_Code__c ORDER BY c.Name DESC SEPARATOR ';') 
from training.course__c course
inner join training.certificate_type__c  ct on course.Id = ct.Course_Name__c
inner join training.bridging_object__c bo on ct.Id = bo.Certificate_Type_Name__c 
inner join training.competency__c c on c.Id = bo.Competency_Name__c
where course.status__c='Active'
group by course.Id;
