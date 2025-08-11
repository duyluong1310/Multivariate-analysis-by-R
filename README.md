# Multivariate-analysis-by-R
## Multiple Regression

OLS, kiểm định giả định, chẩn đoán mô hình.

<details>
<summary>View code</summary>

```r
install.packages("car")      # For diagnostic tools
install.packages("ggplot2")  # For visualization
install.packages("broom")    # For tidy model outputs

# Load dataset
data(mtcars)

# Fit multiple regression model
model <- lm(mpg ~ hp + wt, data = mtcars)

# View summary of regression
summary(model)

# Diagnostic plots
par(mfrow = c(2, 2))
plot(model)

# Variance Inflation Factor (VIF)
library(car)
vif(model)

# Predictions
new_data <- data.frame(hp = c(110, 150), wt = c(2.8, 3.2))
predictions <- predict(model, newdata = new_data)
predictions

# Visualization
library(ggplot2)
ggplot(mtcars, aes(x = hp, y = mpg, color = wt)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE) +
  labs(title = "Multiple Regression Example", x = "Horsepower", y = "Miles per Gallon")
