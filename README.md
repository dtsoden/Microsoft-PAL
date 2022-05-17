# Link a partner ID to Power Platform and Dynamics Customer Insights accounts
Microsoft partners who are Power Platform and Dynamics Customer Insights service providers can associate their service to customers on Microsoft Power Apps, Power Automate, Power BI and Dynamics Customer Insights. You have access to your customer's environment when you, the Microsoft partner, manage, configure, and support Power Platform and Customer Insights resources for your customer. You can use a Directory Account (User / Service), or a Service Principal. Use these Azure credentials plus a location MPN-ID to create the Partner Admin Link (PAL). This will associate your partner network ID (the **location** MPN-ID mentioned earlier) with the Azure credential used for service delivery in your customers production environments.

The PAL allows Microsoft to identify and recognize partners that have Power Platform and Customer Insights customers. Microsoft attributes usage to a partner's organization based on the account's permissions (user role) and scope (tenant, resource, and so on). This attribution can be used for Advanced Specializations, such as the [Microsoft Low Code Advanced Specializations](https://partner.microsoft.com/membership/advanced-specialization#tab-content-2), and [Partner Incentives](https://partner.microsoft.com/asset/collection/microsoft-commerce-incentive-resources#/). 

---
## To ensure success, follow these two guiding principles:

### 1. Get access accounts from your customer
Before you link your partner ID, your customer must give you access to their Production Power Platform or Customer Insights resources. They can use one of the following options:

- **Directory account** - Your customer can create a dedicated user account, or a user account to act as a service account, in their own directory, and provide access to the product(s) you're publishing to Production. If they choose to not grant you access for whatever reason. Ask them to PAL associate the account being used in Production so you can get credit.
- **Service principal** - Your customer can add an app or script from your organization in their directory and provide access to the product you're working on in production. [Use this accelerator script to assist with the creation, and PAL Association](https://github.com/dtsoden/Microsoft-PAL/blob/main/New-PAL-MPN-ID-ServicePrincipal.ps1) The identity of the app or script is known as a service principal. If they choose to not grant you access for whatever reason. Ask them to PAL associate the Service Principal being used in Production so you can get credit.

### 2. Solutions
As a partner, you are required to import your deliverables into the customers Production Environment via a Managed Solution. More about Solutions can be found here [Solutions overview](https://docs.microsoft.com/en-us/power-apps/maker/data-platform/solutions-overview). The reason to use Solutions is because the account used to import Solutions becomes the owner of each deliverable inside the Solution. Use the account from (1. Get access accounts from your customer) above, as this will have the required PAL Association.

</br>

> ***Note: PowerBI & Solutions**
 >> PowerBI Reports & Datasets are not published using Solutions.
 >> For **User/Service Accounts**, the act of [Publishing from the desktop application](https://docs.microsoft.com/en-us/power-bi/create-reports/desktop-upload-desktop-files) determines who owns the report.
 >> For **Service Principal** use [PowerShell](https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.profile/connect-powerbiserviceaccount?view=powerbi-ps) to authenticate, then [PowerShell to Publish](https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.reports/new-powerbireport?view=powerbi-ps).
 >> &nbsp;

<p align="center">
  <img src="https://github.com/dtsoden/Microsoft-PAL/blob/main/images/anatomy.gif">
</p>

---

## Linking access accounts to your partner ID (Location, not Global, MPN-ID), AKA PAL Association.

When you have access to either a Production Environment User Account, or Service Account, use the graphical web-based Azure portal to link your Microsoft Partner Network ID (Location MPN ID). For Service Principal or User Account, or Service Account use, PowerShell, or the Azure CLI to provide the link your Microsoft Partner Network ID (Location MPN ID). Link the partner ID to each customer tenant. 

### Use the Azure portal to link a User Account, or Service Account to your Microsoft Partner Network ID
1. Sign in to the [Azure portal](https://portal.azure.com).
1. Go to [Link to a partner ID](https://portal.azure.com/#blade/Microsoft_Azure_Billing/managementpartnerblade) in the Azure portal.
1. Enter the [Microsoft Partner Network](https://partner.microsoft.com/) ID for your organization. Be sure to use the  **Associated MPN ID**  shown on your partner center profile. It's typically known as your [Partner Location Account MPN ID](/partner-center/account-structure).  
    ![Add Partner ID](https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/media/link-partner-id-power-apps-accounts/link-partner-id.png)
1. To link your partner ID to another customer, switch the directory. Under **Switch directory**, select the appropriate directory.  
    ![Switch Directory](https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/media/link-partner-id-power-apps-accounts/switch-directory.png)

---

## Use PowerShell to link a Service Principal or User Account, or Service Account to your Microsoft Partner Network ID

Install the [Az.ManagementPartner](https://www.powershellgallery.com/packages/Az.ManagementPartner/) Azure PowerShell module.

Sign into the customer's tenant with either the user account or the service principal. For more information, see [Sign in with PowerShell](/powershell/azure/authenticate-azureps).

Link to the new partner ID. The partner ID is the [Microsoft Partner Network](https://partner.microsoft.com/) ID for your organization. Be sure to use the **Associated MPN ID**  shown on your partner profile.

---

### PowerShell Script Template For User/Service Accounts to ADD new - with interactive login ###
For more information, see [Sign in with PowerShell](/powershell/azure/authenticate-azureps).
```azurepowershell-interactive
Connect-AzAccount 
new-AzManagementPartner -PartnerId 12345
Disconnect-AzAccount
```
---

### PowerShell Script Template for Service Principal ###
For more information, see [Sign in with PowerShell](/powershell/azure/authenticate-azureps).
```azurecli-interactive
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
```azurepowershell-interactive
get-AzManagementPartner
```

Update the linked partner ID
```azurepowershell-interactive
Update-AzManagementPartner -PartnerId 12345
```

Delete the linked partner ID
```azurepowershell-interactive
remove-AzManagementPartner -PartnerId 12345
```

---

## Use the Azure CLI to link to a new partner ID For User/Service Accounts

First, install the Azure CLI extension.

```azurecli-interactive
az extension add --name managementpartner
```

Sign into the customer's tenant with either the user account or the service principal. For more information, see [Sign in with the Azure CLI](/cli/azure/authenticate-azure-cli).

```azurecli-interactive
az login --tenant TenantName
```

Link to the new partner ID. The partner ID is the [Microsoft Partner Network](https://partner.microsoft.com/) ID for your organization.

```azurecli-interactive
az managementpartner create --partner-id 12345
```

Get the linked partner ID

```azurecli-interactive
az managementpartner show
```

Update the linked partner ID

```azurecli-interactive
az managementpartner update --partner-id 12345
```

Delete the linked partner ID

```azurecli-interactive
az managementpartner delete --partner-id 12345
```

-----
### Next steps

- Read the [Cost Management + Billing FAQ](../cost-management-billing-faq.yml) for questions and answers about linking a partner ID to Power Apps accounts.
- Join the discussion in the [Microsoft Partner Community](https://aka.ms/PALdiscussion) to receive updates or send feedback.
- Read the [Low Code Application Development advanced specialization FAQ](https://assetsprod.microsoft.com/mpn/faq-low-code-app-development-advanced-specialization.pdf) for PAL-based Power Apps association for Low code application development advanced specialization.
