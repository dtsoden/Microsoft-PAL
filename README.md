# Link a partner ID to Power Platform and Dynamics Customer Insights accounts

Microsoft partners who are Power Platform and Dynamics Customer Insights service providers can associate their service to customers on Microsoft Power Apps, Power Automate, Power BI and Dynamics Customer Insights. You have access to your customer's environment when you, the Microsoft partner, manage, configure, and support Power Platform and Customer Insights resources for your customer. You can use a Directory Account (User / Service), or a Service Principal. Use these Azure credentials plus a location MPN-ID to create the Partner Admin Link (PAL). This will associate your partner network ID (the **location** MPN-ID mentioned earlier) with the Azure credential used for service delivery in your customers' production environments.

The PAL allows Microsoft to identify and recognize partners that have Power Platform and Customer Insights customers. Microsoft attributes usage to a partner's organization based on the account's permissions (user role) and scope (tenant, resource, and so on). This attribution can be used for Advanced Specializations, such as the [Microsoft Low Code Advanced Specializations](https://partner.microsoft.com/membership/advanced-specialization#tab-content-2), and [Partner Incentives](https://partner.microsoft.com/asset/collection/microsoft-commerce-incentive-resources#/).

---

## To ensure success, follow these two guiding principles

### 1\. Get access accounts from your customer

Before you link your partner ID, your customer must give you access to their Production Power Platform or Customer Insights resources. They can use one of the following options:

* **Directory account** - Your customer can create a dedicated user account, or a user account to act as a service account, in their own directory, and provide access to the product(s) you're publishing to Production. If they choose not to grant you access for whatever reason. Ask them to PAL associate with the account being used in production so you can get credit.
* **Service principal** - Your customer can add an app or script from your organization in their directory and provide access to the product you're working on in production. [Use this accelerator script to assist with the creation, and PAL Association](https://github.com/dtsoden/Microsoft-PAL/blob/main/New-PAL-MPN-ID-ServicePrincipal.ps1) The identity of the app or script is known as a service principal. If they choose not to grant you access for whatever reason. Ask them to PAL associate the Service Principal being used in Production so you can get credit.

### 2\. Solutions

It is strongly recommended to use Solutions to import your deliverables into the customers' production environment via a Managed Solution. More about Solutions can be found here [Solutions overview](https://docs.microsoft.com/en-us/power-apps/maker/data-platform/solutions-overview). The reason to use Solutions is because the account used to import Solutions becomes the owner of each deliverable inside the Solution. Use the account from (1. Get access accounts from your customer) above, as this will have the required PAL Association.

> \***Note: PowerBI & Solutions**
>
> > PowerBI Reports & Datasets are not published using Solutions.  
> > For **User/Service Accounts**, the act of [Publishing from the desktop application](https://docs.microsoft.com/en-us/power-bi/create-reports/desktop-upload-desktop-files) determines who owns the report.  
> > For **Service Principal** use [PowerShell to Authenticate,](https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.profile/connect-powerbiserviceaccount?view=powerbi-ps) then [PowerShell to Publish](https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.reports/new-powerbireport?view=powerbi-ps).  

![PAL Anatomy Success](https://github.com/dtsoden/Microsoft-PAL/raw/main/images/anatomy.gif)

---

## Linking access accounts to your partner ID (Location, not Global, MPN-ID), AKA PAL Association

When you have access to either a Production Environment User Account, or Service Account, use the graphical web-based Azure portal to link to your Microsoft Partner Network ID (Location MPN ID). For Service Principal or User Account, or Service Account use, PowerShell, or the Azure CLI to provide the link your Microsoft Partner Network ID (Location MPN ID). Link the partner ID to each customer tenant.

### Use the Azure portal to link a User Account, or Service Account to your Microsoft Partner Network ID

1. Sign in to the [Azure portal](https://portal.azure.com).
2. Go to [Link to a partner ID](https://portal.azure.com/#blade/Microsoft_Azure_Billing/managementpartnerblade) in the Azure portal.
3. Enter the [Microsoft Partner Network](https://partner.microsoft.com/) ID for your organization. Be sure to use the **Associated MPN ID** shown on your partner center profile. It's typically known as your [Partner Location Account MPN ID](/partner-center/account-structure).  
    ![Add Partner ID](https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/media/link-partner-id-power-apps-accounts/link-partner-id.png)
4. To link your partner ID to another customer, switch the directory. Under **Switch directory**, select the appropriate directory.  
    ![Switch Directory](https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/media/link-partner-id-power-apps-accounts/switch-directory.png)

---

## Use PowerShell to link a Service Principal or User Account, or Service Account to your Microsoft Partner Network ID

Install the [Az.ManagementPartner](https://www.powershellgallery.com/packages/Az.ManagementPartner/) Azure PowerShell module.

Sign into the customer's tenant with either the user account or the service principal. For more information, see [Sign in with PowerShell](/powershell/azure/authenticate-azureps).

Link to the new partner ID. The partner ID is the [Microsoft Partner Network](https://partner.microsoft.com/) ID for your organization. Be sure to use the **Associated MPN ID** shown on your partner profile.

---

### PowerShell Script Template For User/Service Accounts to ADD new - with interactive login

For more information, see [Sign in with PowerShell](/powershell/azure/authenticate-azureps).

```plaintext
Connect-AzAccount 
new-AzManagementPartner -PartnerId 12345
Disconnect-AzAccount
```

---

### PowerShell Script Template for Service Principal

For more information, see [Sign in with PowerShell](/powershell/azure/authenticate-azureps).

```plaintext
# Setup the script variables
$appId = #<<YOUR SERVICE PRINCIPAL ID aka AppID GOES HERE>> -  [GUID]
$secretText = #<<YOUR SERVICE PRINCIPAL SECRET GOES HERE>> -  [GUID]
$tenantId = # <<YOUR TENANT GUID GOES HERE>> -  [GUID]
$MPN_ID = # <<YOUR 7 DIGIT LOCATION MPN-ID GOES HERE>> -  [INT]

# Sign in with Service Principal
$SecureStringPwd = $secretText | ConvertTo-SecureString -AsPlainText -Force
$pscredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $appId, $SecureStringPwd
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId

# Assign Partner ID -> example 1234567
New-AzManagementPartner -PartnerId $MPN_ID
Disconnect-AzAccount
```

---

### Additional maintenance PowerShell commands (GET, UPDATE, DELETE) a PAL Association

Get the linked partner ID

```plaintext
get-AzManagementPartner
```

Update the linked partner ID

```plaintext
Update-AzManagementPartner -PartnerId 12345
```

Delete the linked partner ID

```plaintext
remove-AzManagementPartner -PartnerId 12345
```

---

## Use the Azure CLI to link to a new partner ID For User/Service Accounts

First, install the Azure CLI extension.

```plaintext
az extension add --name managementpartner
```

Sign into the customer's tenant with either the user account or the service principal. For more information, see [Sign in with the Azure CLI](/cli/azure/authenticate-azure-cli).

```plaintext
az login --tenant TenantName
```

Link to the new partner ID. The partner ID is the [Microsoft Partner Network](https://partner.microsoft.com/) ID for your organization.

```plaintext
az managementpartner create --partner-id 12345
```

Get the linked partner ID

```plaintext
az managementpartner show
```

Update the linked partner ID

```plaintext
az managementpartner update --partner-id 12345
```

Delete the linked partner ID

```plaintext
az managementpartner delete --partner-id 12345
```

---

## Attribute your access account to the product resource

The use of Solutions negates the need to understand and apply this granular understanding to each product resource.

The partner user/guest account that you received from your customer and was linked through the Partner Admin Link (PAL) needs to be attributed to the _resource_ for Power Platform or Dynamics Customer Insights to count the usage of that specific resource. The user/guest account doesn't need to be associated with a specific Azure subscription for Power Apps, Power Automate, Power BI or D365 Customer Insights. In many cases, it happens automatically, as the partner user is the one creating, editing, and updating the resource. Besides the logic below, the specific programs the PAL link is used for (such as the [Microsoft Low Code Advanced Specializations](https://partner.microsoft.com/membership/advanced-specialization#tab-content-2) or Partner Incentives) may have other requirements such as the resource needing to be in production and associated with paid usage.

| Product | Primary Metric | Resource | Attributed User Logic |
| --- | --- | --- | --- |
| Power Apps | Monthly Active Users (MAU) | Application | The user must be an owner/co-owner of the application. For more information, see [Share a canvas app with your organization](/powerapps/maker/canvas-apps/share-app). In cases of multiple partners being mapped to a single application, the user's activity is reviewed to select the 'latest' partner. |
| Power Automate | Monthly Active Users (MAU) | Flow | The user must be the creator of the flow. There can only be one creator so there's no logic for multiple partners. |
| Power BI | Monthly Active Users (MAU) | Dataset | The user must be the publisher of the dataset. For more information, see [Publish datasets and reports from Power BI Desktop](/power-bi/create-reports/desktop-upload-desktop-files). In cases of multiple partners being mapped to a single dataset, the user's activity is reviewed to select the 'latest' partner. |
| Customer Insights | Unified Profiles | Instance | Any active user of an Instance is treated as the attributed user. In cases of multiple partners being mapped to a single instance, the user's activity is reviewed to select the 'latest' partner. |

### Here are the current known limitations

* **Canvas Applications:**
  * Set the PAL associated User or Service Account as the owner or co-owner of the application.
  * You can only change the owner via the PowerShell Set-AdminPowerAppOwner.
  * When inside of a solution, and imported into another environment, the importing entity becomes the new owner.
* **Model Driven Applications:**
  * Make sure the app creator has a PAL association.
  * There is NO co-owner option, and you cannot change the owner via the GUI or PowerShell directly.
  * When inside of a solution, and imported into another environment, the importing entity becomes the new owner.
* **Power Automate:**
  * Make sure the app creator has a PAL association
  * There is no co-owner option
  * You can easily change the owner via the web GUI or with the PowerShell Set-AdminFlowOwnerRole
  * When inside of a solution, and imported into another environment, the importing entity becomes the new owner.
* **Power BI:**
  * The act of publishing to the service sets the owner.
  * Make sure the user publishing the report has a PAL association.
  * Use PowerShell to publish as any user or Service Account,
* **Power Virtual Agents:**
  * Make sure the Bot creator has a PAL association.
  * You can not change the owner in the GUI or via a PowerShell command.
  * When inside of a solution, and imported into another environment, the importing entity becomes the new owner.

#### Owner / Co-owner Compatibility as a Glance

*Delivering one or many items?* 
We must strongly recommend Solutions as the method of owner change; this is because of the unfortunate lack of features across the Power Platform to support ownership changes directly against individual assets.

Can you change the owner of an object directly outside of a solution?

| Product | GUI | PowerShell | PP CLI | DevOps + Build Tools |
| --- | --- | --- | --- | --- |
| Power App Canvas | YES | YES | NO | NO |
| Power App Model Driven | NO | NO | NO | NO |
| Power Automate | YES | YES | NO | NO |
| Power BI (Publishing) | NO | YES | NO | NO |
| Power Virtual Agent | NO | NO | NO | NO |

Can you change the owner of an objects contained inside of a solution by importing said Solution? In other words the person inporting the Solution becomes the new owner of all objects inside of the soluiton.

| Product | GUI | PowerShell | PP CLI | DevOps + Build Tools |
| --- | --- | --- | --- | --- |
| Power App Canvas | YES | YES | YES | YES |
| Power App Model Driven | YES | NO | YES | YES |
| Power Automate | YES | YES | YES | YES |
| Power BI (Publishing) | NO | YES | NO | NO |
| Power Virtual Agent | YES | NO | YES | YES |


This shows the compatibility in scope to changing a previously assigned user account to an Application Registration known as a Service Principal that has a PAL association and is inside of a Solution.

| Product | GUI | PowerShell | PP CLI | DevOps + Build Tools |
| --- | --- | --- | --- | --- |
| Power App Canvas | NO | NO | YES | YES |
| Power App Model Driven | NO | NO | YES | YES |
| Power Automate | YES | YES | YES | YES |
| Power BI (Publishing) | NO | YES | NO | NO |
| Power Virtual Agent | NO | NO | YES | YES |

---

### Next steps

* Read the [Cost Management + Billing FAQ](../cost-management-billing-faq.yml) for questions and answers about linking a partner ID to Power Apps accounts.
* Join the discussion in the [Microsoft Partner Community](https://aka.ms/PALdiscussion) to receive updates or send feedback.
* Read the [Low Code Application Development advanced specialization FAQ](https://assetsprod.microsoft.com/mpn/faq-low-code-app-development-advanced-specialization.pdf) for PAL-based Power Apps association for Low code application development advanced specialization.
