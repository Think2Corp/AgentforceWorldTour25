public with sharing class GetContactByName {
  public class Input {
    @InvocableVariable(required=true description='Name to search for')
    public String name;
  }

  public class Output {
    @InvocableVariable(description='Result message')
    public String message;
    @InvocableVariable(description='Result object as JSON string')
    public String resultObject;
    @InvocableVariable(description='List of Contact sObjects')
    public List<Contact> contactList;

    public Output(
      String message,
      String resultObject,
      List<Contact> contactList
    ) {
      this.message = message;
      this.resultObject = resultObject;
      this.contactList = contactList;
    }
  }

  @InvocableMethod(
    label='Get Contacts By Name'
    description='Returns contacts that match the given name pattern'
  )
  public static List<Output> searchContacts(List<Input> inputs) {
    List<Output> results = new List<Output>();

    if (inputs == null || inputs.isEmpty()) {
      results.add(new Output('No input provided', null, null));
      return results;
    }

    Set<String> searchPatterns = new Set<String>();
    for (Input input : inputs) {
      if (String.isNotBlank(input.name)) {
        searchPatterns.add('%' + input.name + '%');
      }
    }

    if (searchPatterns.isEmpty()) {
      results.add(new Output('No valid search patterns provided', null, null));
      return results;
    }

    Map<String, List<Contact>> contactsByPattern = new Map<String, List<Contact>>();
    List<Contact> allContacts = [
      SELECT Id, FirstName, LastName, Email, Phone, Name
      FROM Contact
      WHERE Name LIKE :searchPatterns
      LIMIT 1000
    ];

    if (allContacts.isEmpty()) {
      for (Input input : inputs) {
        results.add(
          new Output(
            'No contacts found for pattern: ' + input.name,
            null,
            new List<Contact>()
          )
        );
      }
      return results;
    }

    // Organize contacts by search pattern
    for (Contact c : allContacts) {
      for (Input input : inputs) {
        String pattern = '%' + input.name + '%';
        if (c.Name.toLowerCase().contains(input.name.toLowerCase())) {
          if (!contactsByPattern.containsKey(input.name)) {
            contactsByPattern.put(input.name, new List<Contact>());
          }
          if (contactsByPattern.get(input.name).size() < 10) {
            contactsByPattern.get(input.name).add(c);
          }
        }
      }
    }

    // Create output for each input
    for (Input input : inputs) {
      List<Contact> matchingContacts = contactsByPattern.get(input.name);
      if (matchingContacts != null && !matchingContacts.isEmpty()) {
        results.add(
          new Output(
            'Found ' +
              matchingContacts.size() +
              ' contacts matching: ' +
              input.name,
            null,
            matchingContacts
          )
        );
      } else {
        results.add(
          new Output(
            'No contacts found matching: ' + input.name,
            null,
            new List<Contact>()
          )
        );
      }
    }

    return results;
  }
}
