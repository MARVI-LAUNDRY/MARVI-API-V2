import Stripe from "stripe";
import {updateOrder} from "../model/ordersModel.js";
import dotenv from "dotenv";

dotenv.config();

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export const createPaymentSession = async (data) => {
    {
        try {
            const session = await stripe.checkout.sessions.create({
                mode: "payment", line_items: [{
                    price_data: {
                        currency: data.currency, product_data: {name: data.order}, unit_amount: data.amount, // en centavos
                    }, quantity: 1,
                },], metadata: {
                    order: data.order
                }, success_url: data.successUrl, cancel_url: data.cancelUrl,
            });

            return {
                success: true, data: session.url, message: "Pedido registrado y sesión de pago creada exitosamente"
            }
        } catch (error) {
            return {
                success: false, error: "Error al crear la sesión de pago", message: error.message
            }
        }
    }
}

export const stripeWebhook = async (req, res) => {
    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

    const sig = req.headers["stripe-signature"];

    try {
        const event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);

        if (event.type === "checkout.session.completed") {
            const session = event.data.object;
            const data = {folio: session.metadata.order, estado: 'P'};
            const result = await updateOrder(data)

            if (result.success) res.status(200).json(result);
        }
        console.log("Pedido pagado:", event.data.object.metadata.order);
    } catch (error) {
        res.status(400).json({success: false, message: "Webhook error", error: error.message});
    }
}