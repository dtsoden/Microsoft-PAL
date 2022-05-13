# Link a partner ID to Power Platform and Dynamics Customer Insights accounts
Microsoft partners who are Power Platform and Dynamics Customer Insights service providers can associate their service to customers on Microsoft Power Apps, Power Automate, Power BI and Dynamics Customer Insights. You have access to your customer's environment when you, the Microsoft partner, manage, configure, and support Power Platform and Customer Insights resources for your customer. You can use a Directory Account (User / Service), or a Service Principal. Use these Azure credentials plus a location MPN-ID to create the Partner Admin Link (PAL). This will associate your partner network ID (the location MPN-ID mentioned earlier) with the Azure credential used for service delivery in your customers production environments.

The PAL allows Microsoft to identify and recognize partners that have Power Platform and Customer Insights customers. Microsoft attributes usage to a partner's organization based on the account's permissions (user role) and scope (tenant, resource, and so on). This attribution can be used for Advanced Specializations, such as the [Microsoft Low Code Advanced Specializations](https://partner.microsoft.com/membership/advanced-specialization#tab-content-2), and [Partner Incentives](https://partner.microsoft.com/asset/collection/microsoft-commerce-incentive-resources#/). 
##To ensure success, follow these guiding principles:
### 1. Solutions
As a partner, you are required to import your deliverables into the customers production environment via a solution. More about solutions can be found here https://docs.microsoft.com/en-us/power-apps/maker/data-platform/solutions-overview 

### 2. Get access from your customer
Before you link your partner ID, your customer must give you access to their Production Power Platform or Customer Insights resources. They can use one of the following options:

- **Directory account** - Your customer can create a dedicated user account, or a user account to act as a service account, in their own directory, and provide access to the product(s) you're publishing to Production. If they choose to not grant you access for whatever reason. Ask them to PAL associate the account being used in production so you can get credit.
- **Service principal** - Your customer can add an app or script from your organization in their directory and provide access to the product you're working on in production. The identity of the app or script is known as a service principal. If they choose to not grant you access for whatever reason. Ask them to PAL associate the Service Principal being used in production so you can get credit.


## Linking accounts to your partner ID

When you have access to either a Production Environment User Account, or Service Account, use the graphical web-based Azure portal to link your Microsoft Partner Network ID (Location MPN ID). For Service Principal or User Account, or Service Account use, PowerShell, or the Azure CLI to provide the link your Microsoft Partner Network ID (Location MPN ID). Link the partner ID to each customer tenant. 

### Use the Azure portal to link a User Account, or Service Account to your Microsoft Partner Network ID
1. Sign in to the [Azure portal](https://portal.azure.com).
1. Go to [Link to a partner ID](https://portal.azure.com/#blade/Microsoft_Azure_Billing/managementpartnerblade) in the Azure portal.
1. Enter the [Microsoft Partner Network](https://partner.microsoft.com/) ID for your organization. Be sure to use the  **Associated MPN ID**  shown on your partner center profile. It's typically known as your [Partner Location Account MPN ID](/partner-center/account-structure).  
    :::image type="content" source="./media/link-partner-id-power-apps-accounts/link-partner-id.png" alt-text="Screenshot showing the Link to a partner ID window." lightbox="./media/link-partner-id-power-apps-accounts/link-partner-id.png" :::
1. To link your partner ID to another customer, switch the directory. Under **Switch directory**, select the appropriate directory.  
    :::image type="content" source="./media/link-partner-id-power-apps-accounts/switch-directory.png" alt-text="Screenshot showing the Directory + subscription window where can you switch your directory." lightbox="./media/link-partner-id-power-apps-accounts/switch-directory.png" :::

### Use PowerShell to link a Service Principal or User Account, or Service Account to your Microsoft Partner Network ID

Install the [Az.ManagementPartner](https://www.powershellgallery.com/packages/Az.ManagementPartner/) Azure PowerShell module.

Sign into the customer's tenant with either the user account or the service principal. For more information, see [Sign in with PowerShell](/powershell/azure/authenticate-azureps).

```azurepowershell-interactive
Update-AzManagementPartner -PartnerId 12345
```

Link to the new partner ID. The partner ID is the [Microsoft Partner Network](https://partner.microsoft.com/) ID for your organization. Be sure to use the **Associated MPN ID**  shown on your partner profile.

```azurepowershell-interactive
new-AzManagementPartner -PartnerId 12345
```

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

### Use the Azure CLI to link to a new partner ID

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

## Attribute your access account to the product resource

The partner user/guest account that you received from your customer and was linked through the Partner Admin Link (PAL) needs to be attributed to the *resource* for Power Platform or Dynamics Customer Insights to count the usage of that specific resource. The user/guest account doesn't need to be associated with a specific Azure subscription for Power Apps, Power Automate, Power BI or D365 Customer Insights. In many cases, it happens automatically, as the partner user is the one creating, editing, and updating the resource. Besides the logic below, the specific programs the PAL link is used for (such as the [Microsoft Low Code Advanced Specializations](https://partner.microsoft.com/membership/advanced-specialization#tab-content-2) or Partner Incentives) may have other requirements such as the resource needing to be in production and associated with paid usage.

| Product           | Primary Metric   | Resource | Attributed User Logic                                                                                                                                                                             |
|-------------------|------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Power Apps | Monthly Active Users (MAU) | Application |The user must be an owner/co-owner of the application. For more information, see [Share a canvas app with your organization](/powerapps/maker/canvas-apps/share-app). In cases of multiple partners being mapped to a single application, the user's activity is reviewed to select the 'latest' partner. |
| Power Automate | Monthly Active Users (MAU) | Flow | The user must be the creator of the flow. There can only be one creator so there's no logic for multiple partners.  |
| Power BI            | Monthly Active Users (MAU)   | Dataset | The user must be the publisher of the dataset. For more information, see [Publish datasets and reports from Power BI Desktop](/power-bi/create-reports/desktop-upload-desktop-files). In cases of multiple partners being mapped to a single dataset, the user's activity is reviewed to select the 'latest' partner. |
| Customer Insights | Unified Profiles | Instance | Any active user of an Instance is treated as the attributed user. In cases of multiple partners being mapped to a single Instance, the user's activity is reviewed to select the 'latest' partner |


### Next steps

- Read the [Cost Management + Billing FAQ](../cost-management-billing-faq.yml) for questions and answers about linking a partner ID to Power Apps accounts.
- Join the discussion in the [Microsoft Partner Community](https://aka.ms/PALdiscussion) to receive updates or send feedback.
- Read the [Low Code Application Development advanced specialization FAQ](https://assetsprod.microsoft.com/mpn/faq-low-code-app-development-advanced-specialization.pdf) for PAL-based Power Apps association for Low code application development advanced specialization.
